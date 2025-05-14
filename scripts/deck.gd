extends StaticBody3D
class_name Deck

# --- Exported ---
@export var spawn_point_path: NodePath = "SpawnPoint"

# --- Signals ---
signal card_drawn(card: Card)

# --- Nodes ---
@onready var touch_area: Area3D = $TouchTrigger
@onready var spawn_point_node: Node3D = get_node(spawn_point_path)
@onready var flip_card_sound: AudioStreamPlayer3D = $FlippingCardSound

# --- State ---
var game_started := false
var vira_card: Card
var deck: Array[Card] = []

# --- Constants ---
const SUITS = ["s", "h", "d", "c"]
const VALUES = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const CARD_SCENE: PackedScene = preload("res://scenes/card.tscn")

# --- Ready ---
func _ready():
	randomize()
	touch_area.body_entered.connect(_on_deck_touched)

# --- Touch to start game ---
func _on_deck_touched(body: Node) -> void:
	if game_started or not body.is_in_group("players"):
		return
	game_started = true
	start_truco_round()

# --- Start round ---
func start_truco_round():
	setup_deck()
	await get_tree().process_frame

	var full_hands: Array[Node3D] = [
		GameManager.bot1_hand,
		GameManager.bot2_hand,
		GameManager.bot3_hand,
		GameManager.player_hand
	]

	var start_index := (GameManager.dealer_index + 1) % 4
	var hands: Array[Node3D] = []

	for i in 4:
		hands.append(full_hands[(start_index + i) % 4])

	print("🃎 Dealing order:", hands.map(func(h): return h.name))

	await _animate_card_dealing(hands, 3)
	await get_tree().process_frame
	await _reveal_vira()

# --- Build and shuffle deck ---
func setup_deck():
	for child in get_children():
		if child is Card:
			remove_child(child)
			child.queue_free()

	deck.clear()
	for suit in SUITS:
		for value in VALUES:
			var id = "%s%s" % [suit, value]
			if not CardGameRules.is_card_allowed(id, GameManager.current_game):
				continue

			var card: Card = CARD_SCENE.instantiate()
			card.set_card(id, false)
			card.card_name = id
			card.show_back()
			card.visible = false
			add_child(card)
			deck.append(card)

	_shuffle_deck()
	_position_cards()

	for c in deck:
		print("🧩 Card in deck:", c.card_name)

func _shuffle_deck():
	deck.shuffle()

func _position_cards():
	var offset_y := 0.005
	var base_height := 0.02

	for i in deck.size():
		var card = deck[i]
		card.visible = false
		card.position = Vector3(0, base_height + i * offset_y, 0)
		card.rotation_degrees = Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-2.0, 2.0),
			randf_range(-0.2, 0.2)
		)
		if card.has_node("XRToolsPickable"):
			card.get_node("XRToolsPickable").set_physics_process(false)

# --- Draw card ---
func draw_card() -> Card:
	if deck.is_empty():
		return null

	var card: Card = deck.pop_back()
	card.set_card(card.card_name, false)
	card.visible = true
	card.reparent(get_tree().current_scene)
	card.global_transform = spawn_point_node.global_transform.translated(Vector3(0, 0.05, 0))

	emit_signal("card_drawn", card)
	return card

# --- Animate dealing ---
func _animate_card_dealing(hands: Array[Node3D], cards_per_hand: int = 3) -> void:
	var total_cards := cards_per_hand * hands.size()
	var hand_index := 0

	for i in total_cards:
		if deck.is_empty():
			break

		var card = deck.pop_back()
		card.visible = true
		card.global_transform = spawn_point_node.global_transform

		var current_hand = hands[hand_index]
		var slot_index := int(i / hands.size()) + 1
		var card_slot = current_hand.get_node_or_null("CardSlot%d" % slot_index)

		if card_slot:
			var tween := create_tween()
			tween.tween_property(card, "global_transform:origin", card_slot.global_transform.origin, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await tween.finished

			card.reparent(card_slot)
			card.transform = Transform3D.IDENTITY

		await get_tree().create_timer(0.05).timeout
		hand_index = (hand_index + 1) % hands.size()

	# Assign cards
	for hand in hands:
		var cards := []
		for child in hand.get_children():
			if child.name.begins_with("CardSlot") and child.get_child_count() > 0:
				cards.append(child.get_child(0))
		if "set_cards" in hand:
			hand.call("set_cards", cards)

# --- Reveal vira with flip and slide ---
func _reveal_vira() -> void:
	vira_card = draw_card()
	if not vira_card:
		push_error("❌ Failed to draw vira card")
		return

	# Set card face and update textures
	vira_card.set_card(vira_card.card_name, true)
	vira_card._update_textures()
	vira_card.visible = true
	vira_card.scale = Vector3.ONE
	vira_card.rotation_degrees = Vector3.ZERO

	# Disable physics/grab logic if applicable
	if vira_card.has_node("XRToolsPickable"):
		vira_card.get_node("XRToolsPickable").set_physics_process(false)

	# Calculate the desired global transform
	var deck_global_transform = global_transform
	var deck_height = deck.size() * 0.005 + 0.02
	var vira_global_position = deck_global_transform.origin + Vector3(0.06, deck_height * 0.5 - 0.01, 0)

	var vira_basis = Basis()
	vira_basis = vira_basis.rotated(Vector3(1, 0, 0), deg_to_rad(90)) # Lay flat
	vira_basis = vira_basis.rotated(Vector3(0, 1, 0), deg_to_rad(90)) # Rotate toward player

	var vira_global_transform = Transform3D(vira_basis, vira_global_position)

	# Set the global transform before reparenting
	vira_card.global_transform = vira_global_transform

	# Reparent the card to the deck, preserving the global transform
	vira_card.reparent(self, true)

	# Ensure correct visual side
	var front = vira_card.get_node_or_null("XRToolsPickable/CardBody/Front")
	var back = vira_card.get_node_or_null("XRToolsPickable/CardBody/Back")
	if front:
		front.visible = true
	if back:
		back.visible = false

	if flip_card_sound:
		flip_card_sound.play()

	if vira_card.has_method("freeze"):
		vira_card.freeze = true

	print("🃏 Vira card name:", vira_card.card_name)
	print("📍 Vira global position:", vira_card.global_transform.origin)
	print("📍 Deck global position:", deck_global_transform.origin)
	print("📦 Deck height estimate:", deck_height)

	CardRanks.set_vira(vira_card.card_name)
