extends Node3D
class_name Arena

# Scenes
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var palm_menu_scene: PackedScene = preload("res://scenes/palmMenu.tscn")
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")
var player_scene: PackedScene = preload("res://scenes/player.tscn")

# Instances
var player_instance: XROrigin3D
var left_palm_menu: PalmMenu
var right_palm_menu: PalmMenu
var deck_instance: Deck
var chairs: Array[Chair] = []

enum HandOwner {NONE = -1, LEFT = 0, RIGHT = 1}
var current_menu_owner: HandOwner = HandOwner.NONE

# Nodes
@onready var table_node: Node3D = $Table
@onready var player_chair: Chair = $Chairs/Chair1
@onready var bot1: Node3D = $Chairs/Chair2/Bot1
@onready var bot2: Node3D = $Chairs/Chair3/Bot2
@onready var bot3: Node3D = $Chairs/Chair4/Bot3
@onready var left_hand: Node3D = null
@onready var right_hand: Node3D = null
@onready var camera: Camera3D = null


func _ready():
	chairs = [
		$Chairs/Chair1,
		$Chairs/Chair2,
		$Chairs/Chair3,
		$Chairs/Chair4
	]

	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	_spawn_player()
	_spawn_palm_menus()
	_spawn_deck()
	_seat_bots()

	GameManager.player_hand = left_palm_menu.get_node("CardHand")
	GameManager.bot1_hand = $Chairs/Chair2/Bot1/CardHand
	GameManager.bot2_hand = $Chairs/Chair3/Bot2/CardHand
	GameManager.bot3_hand = $Chairs/Chair4/Bot3/CardHand

	GameManager.setup_round()

# --- Palm Menu Logic ---
func _process(_delta: float) -> void:
	var left_up := _is_palm_up(left_hand)
	var right_up := _is_palm_up(right_hand)

	match current_menu_owner:
		HandOwner.NONE:
			if left_up:
				current_menu_owner = HandOwner.LEFT
			elif right_up:
				current_menu_owner = HandOwner.RIGHT

		HandOwner.LEFT:
			if left_up:
				_check_hand_orientation(left_hand, left_palm_menu, true)
			else:
				PalmMenuManager.hide_menu(true)
				current_menu_owner = HandOwner.NONE

		HandOwner.RIGHT:
			if right_up:
				_check_hand_orientation(right_hand, right_palm_menu, false)
			else:
				PalmMenuManager.hide_menu(false)
				current_menu_owner = HandOwner.NONE


func _is_palm_up(hand: Node3D) -> bool:
	if hand == null:
		return false
	var palm_normal = hand.global_transform.basis.z.normalized()
	return palm_normal.dot(Vector3.UP) > 0.85


func _check_hand_orientation(hand: Node3D, menu: PalmMenu, is_left: bool) -> void:
	if hand == null or menu == null:
		return

	var palm_normal = hand.global_transform.basis.z.normalized()
	var dot_up = palm_normal.dot(Vector3.UP)

	if dot_up > 0.85:
		# Position the menu above the palm
		menu.global_transform.origin = hand.global_transform.origin + palm_normal * 0.15

		# Rotate so it's vertical and facing the camera
		var up = palm_normal
		var forward = (camera.global_transform.origin - menu.global_transform.origin).normalized()
		var right = up.cross(forward).normalized()
		forward = right.cross(up).normalized()

		menu.global_transform = Transform3D(Basis(right, up, forward), hand.global_transform.origin + palm_normal * 0.25)
		menu.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))

		PalmMenuManager.show_menu(is_left)
	else:
		PalmMenuManager.hide_menu(is_left)


func _spawn_palm_menus() -> void:
	left_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	left_palm_menu.is_left_hand = true
	get_tree().current_scene.add_child(left_palm_menu)

	right_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	right_palm_menu.is_left_hand = false
	get_tree().current_scene.add_child(right_palm_menu)


# --- Player Seating ---
func _spawn_player() -> void:
	if not player_scene:
		push_error("Player scene not assigned.")
		return

	# Instance player
	player_instance = player_scene.instantiate() as XROrigin3D
	get_tree().current_scene.add_child(player_instance)

	# Align to chair with offset
	var chair_pos := player_chair.global_transform.origin
	var spawn_pos := chair_pos + Vector3(0, 0, 0)
	var _look_at := table_node.global_transform.origin
	_look_at.y = spawn_pos.y

	var _basis := Transform3D().looking_at(_look_at - spawn_pos, Vector3.UP).basis

	player_instance.global_transform = Transform3D(_basis, spawn_pos)

	# 🟩 Save table position for use in Player recenter logic
	if player_instance is Player:
		player_instance.table_position = table_node.global_transform.origin
	
	left_hand = player_instance.get_node("LeftTrackedHand")
	right_hand = player_instance.get_node("RightTrackedHand")
	camera = player_instance.get_node("XRCamera3D")


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
	get_tree().current_scene.add_child(deck_instance)
	deck_instance.global_transform = deck_spawn.global_transform.translated(Vector3.UP * 0.01)
	deck_instance.scale = Vector3.ONE
	deck_instance.spawn_point_node = deck_spawn
	deck_instance.setup_deck()

	GameManager.deck = deck_instance

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
	bot.translate(Vector3(0, 1.1, 0))
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
	vira_card.transform.origin = Vector3(0, -0.01, 0)
	vira_card.rotation_degrees = Vector3(90, 0, 0)
	if vira_card.has_method("freeze"):
		vira_card.freeze = true
