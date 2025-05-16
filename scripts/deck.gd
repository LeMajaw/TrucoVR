extends Node3D
class_name Deck

# --- Exported ---
@export var spawn_point_path: NodePath = "SpawnPoint"

# --- Signals ---
signal card_drawn(card: Card)

# --- Nodes ---
@onready var touch_area: Area3D = $TouchTrigger
@onready var spawn_point_node: Node3D = get_node(spawn_point_path)
@onready var flip_card_sound: AudioStreamPlayer3D = $FlippingCardSound
@onready var vira_spawn_node: Marker3D = $ViraSpawnPoint

# --- State ---
var game_started := false
var deck: Array[Card] = []
var vira_card: Card

# --- Constants ---
const SUITS = ["spades", "hearts", "diamonds", "clubs"]
const VALUES = ["ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"]
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
	_reveal_vira()

# --- Build and shuffle deck ---
func setup_deck():
	for child in get_children():
		if child is Card and child != vira_card:
			remove_child(child)
			child.queue_free()

	deck.clear()
	for suit in SUITS:
		for value in VALUES:
			var id = "%s_%s" % [value, suit]
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

# --- Reveal vira ---
func spawn_vira_card(card_data: Dictionary) -> Card:
	var new_vira_card = CARD_SCENE.instantiate() as Card
	add_child(new_vira_card)

	new_vira_card.set_card(card_data.name, true)
	new_vira_card.visible = true
	new_vira_card.scale = Vector3.ONE

	await get_tree().process_frame # 🔁 ensure all @onready vars initialized
	print("🧪 Vira spawn valid?:", is_instance_valid(vira_spawn_node))
	print("🧪 Node path:", vira_spawn_node.get_path() if is_instance_valid(vira_spawn_node) else "NULL")

	_set_vira_transform(new_vira_card)

	return new_vira_card

func _set_vira_transform(card: Card) -> void:
	if not is_instance_valid(card) or not is_instance_valid(vira_spawn_node):
		push_error("❌ Invalid instances in _set_vira_transform")
		return

	# Use the spawn node's full transform for position and rotation
	var transform := vira_spawn_node.global_transform

	transform.basis = Basis(Vector3.UP, deg_to_rad(90)) * transform.basis

	card.global_transform = transform
	card.freeze_card()

	print("✅ Vira card placed at:", transform.origin)
	print("🎯 Vira rotation basis:", transform.basis)

func _reveal_vira() -> void:
	if deck.is_empty():
		push_error("❌ Deck is empty when trying to draw vira")
		return

	var vira_id = deck.pop_back().card_name

	if vira_card and vira_card.is_inside_tree():
		vira_card.queue_free()
		await get_tree().process_frame

	var new_vira = await spawn_vira_card({"name": vira_id})
	new_vira.freeze_card()

	vira_card = new_vira

	if flip_card_sound:
		flip_card_sound.play()

	CardRanks.set_vira(vira_id)

	print("🃏 Vira card name:", vira_id)
	print("📦 Deck position:", global_transform.origin)
