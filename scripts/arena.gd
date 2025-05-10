extends Node3D
class_name Arena

# Scenes
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var palm_menu_scene: PackedScene = preload("res://scenes/palmMenu.tscn")
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")

# Instances
var left_palm_menu: PalmMenu
var right_palm_menu: PalmMenu
var deck_instance: Deck
var chairs: Array[Chair] = []

# Nodes
@onready var table_node: Node3D = $Table
@onready var player_chair: Chair = $Chairs/Chair1
@onready var player: Node3D = $Chairs/Chair1/Player
@onready var left_hand: Node3D = $Chairs/Chair1/Player/LeftTrackedHand
@onready var right_hand: Node3D = $Chairs/Chair1/Player/RightTrackedHand
@onready var camera: Camera3D = $Chairs/Chair1/Player/XRCamera3D
@onready var bot1: Node3D = $Chairs/Chair2/Bot1
@onready var bot2: Node3D = $Chairs/Chair3/Bot2
@onready var bot3: Node3D = $Chairs/Chair4/Bot3

func _ready():
	chairs = [
		$Chairs/Chair1,
		$Chairs/Chair2,
		$Chairs/Chair3,
		$Chairs/Chair4
	]

	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	_seat_player(player)
	_spawn_palm_menus()
	_spawn_deck()
	_seat_bots()

	# Assign player and bot hands to GameManager (for dealing)
	GameManager.player_hand = $Chairs/Chair1/Player/PalmMenu/CardHand
	GameManager.bot1_hand = $Chairs/Chair2/Bot1/CardHand
	GameManager.bot2_hand = $Chairs/Chair3/Bot2/CardHand
	GameManager.bot3_hand = $Chairs/Chair4/Bot3/CardHand

	# ✅ Start the round!
	GameManager.setup_round()

# --- Palm Menu Logic ---
func _process(_delta: float) -> void:
	if left_palm_menu and _is_hand_palm_up(left_hand):
		_update_palm_menu_position(left_palm_menu, left_hand)
		PalmMenuManager.show_menu(true)
	elif right_palm_menu and _is_hand_palm_up(right_hand):
		_update_palm_menu_position(right_palm_menu, right_hand)
		PalmMenuManager.show_menu(false)
	else:
		PalmMenuManager.hide_menu(true)
		PalmMenuManager.hide_menu(false)

func _is_hand_palm_up(hand: Node3D) -> bool:
	if hand == null:
		return false
	var palm_up_vector := hand.global_transform.basis.y.normalized()
	return palm_up_vector.dot(Vector3.UP) > 0.85

func _update_palm_menu_position(menu: PalmMenu, hand: Node3D) -> void:
	var palm_up := hand.global_transform.basis.y.normalized()
	var palm_pos := hand.global_transform.origin
	menu.global_transform.origin = palm_pos + palm_up * 0.15

	var look_at_pos := camera.global_transform.origin
	menu.look_at(look_at_pos, Vector3.UP)
	menu.rotate_object_local(Vector3.RIGHT, deg_to_rad(-15))

func _spawn_palm_menus() -> void:
	left_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	left_palm_menu.is_left_hand = true
	player.add_child(left_palm_menu)

	right_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	right_palm_menu.is_left_hand = false
	player.add_child(right_palm_menu)

# --- Player Seating ---
func _seat_player(player_node: Node3D) -> void:
	if not is_instance_valid(player_node):
		push_error("Player not found.")
		return

	if player_chair.has_method("seat_player"):
		player_chair.seat_player(player_node)

		# Force XR Origin absolute position for VR
		var xr_origin := player_node.get_node("XROrigin3D")
		if xr_origin:
			xr_origin.global_transform.origin = player_chair.global_transform.origin + Vector3(0, 0.85, 0)
			xr_origin.global_transform.basis = player_chair.global_transform.basis
	else:
		push_error("Chair1 missing seat_player()")

# --- Deck Spawn ---
func _spawn_deck() -> void:
	if not deck_scene or not is_instance_valid(table_node):
		push_warning("Deck scene not assigned or table not ready.")
		return

	var deck_spawn = table_node.get_node_or_null("DeckSpawnPoint")
	if deck_spawn == null:
		push_error("DeckSpawnPoint not found in table node.")
		return

	deck_instance = deck_scene.instantiate() as Deck

	# Add to root scene to avoid inheriting table's scale
	get_tree().current_scene.add_child(deck_instance)
	deck_instance.global_transform = deck_spawn.global_transform.translated(Vector3.UP * 0.01)
	deck_instance.scale = Vector3.ONE # Just in case

	# Setup deck
	deck_instance.spawn_point_node = deck_spawn
	deck_instance.setup_deck()

	# 💡 Register deck reference in GameManager
	GameManager.deck = deck_instance

	# Also set Vira marker if you have one
	var vira_marker = table_node.get_node_or_null("ViraMarker")
	if vira_marker:
		GameManager.vira_card_position = vira_marker
	else:
		push_warning("🟡 No ViraMarker found — vira card will not be positioned.")

	print("✅ Deck placed at:", deck_instance.global_transform.origin)

# --- Bot Seating ---
func _seat_bots() -> void:
	bot1.team = Bot.Team.ENEMY_TEAM
	bot2.team = Bot.Team.PLAYER_TEAM
	bot3.team = Bot.Team.ENEMY_TEAM

	bot1.difficulty = Bot.Difficulty.NORMAL
	bot2.difficulty = Bot.Difficulty.HARD
	bot3.difficulty = Bot.Difficulty.EXPERT

	bot1.apply_bot_appearance()
	bot2.apply_bot_appearance()
	bot3.apply_bot_appearance()

	_adjust_bot(bot1, $Chairs/Chair2)
	_adjust_bot(bot2, $Chairs/Chair3)
	_adjust_bot(bot3, $Chairs/Chair4)

func _adjust_bot(bot: Bot, chair: Chair) -> void:
	if not is_instance_valid(bot) or not is_instance_valid(chair):
		push_warning("❗ Bot or Chair invalid.")
		return

	chair.seat_player(bot)
	bot.translate(Vector3(0, 1.2, 0))
	bot.scale = Vector3(0.35, 0.35, 0.35)

	print("🤖", bot.name, "seated at", chair.name)

# --- Card Placement ---
func place_card_in_hand(card: Node3D, card_hand: Node3D, slot_index: int):
	var slot_path := "CardSlots/CardSlot%d" % (slot_index + 1)
	var card_slot := card_hand.get_node_or_null(slot_path)
	if card_slot:
		card.reparent(card_hand)
		card.global_transform = card_slot.global_transform
		if card.has_method("freeze"):
			card.freeze = true

# --- Vira Placement ---
func place_vira_card(vira_card: Node3D, deck_node: Node3D):
	vira_card.reparent(deck_node)
	vira_card.transform.origin = Vector3(0, -0.01, 0)  # adjust based on your card thickness
	vira_card.rotation_degrees = Vector3(90, 0, 0)
	if vira_card.has_method("freeze"):
		vira_card.freeze = true
