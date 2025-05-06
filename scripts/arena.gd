extends Node3D
class_name Arena

# Scenes
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var palm_menu_scene: PackedScene = preload("res://scenes/palmMenu.tscn")
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")

# Instances
var palm_menu: PalmMenu
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
	_spawn_palm_menu()
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
	if palm_menu == null:
		return

	var left_up: bool = _is_hand_palm_up(left_hand)
	var right_up: bool = _is_hand_palm_up(right_hand)

	if left_up or right_up:
		var active_hand: Node3D = right_hand if right_up else left_hand

		var palm_up: Vector3 = active_hand.global_transform.basis.y.normalized()
		var palm_pos: Vector3 = active_hand.global_transform.origin
		palm_menu.global_transform.origin = palm_pos + palm_up * 0.15

		var look_at_pos: Vector3 = camera.global_transform.origin
		palm_menu.look_at(look_at_pos, Vector3.UP)

		var palm_forward: Vector3 = active_hand.global_transform.basis.z.normalized()
		palm_menu.rotate_object_local(Vector3.RIGHT, deg_to_rad(-15))

		palm_menu.show_menu()
	else:
		palm_menu.hide_menu()


func _is_hand_palm_up(hand: Node3D) -> bool:
	if hand == null:
		return false

	# Get hand "up" vector (local +Y)
	var palm_up_vector := hand.global_transform.basis.y.normalized()

	# Check angle between hand's up and world up
	var dot := palm_up_vector.dot(Vector3.UP)

	# Threshold closer to 1.0 = more strictly facing up
	return dot > 0.85


func _spawn_palm_menu() -> void:
	palm_menu = palm_menu_scene.instantiate() as PalmMenu
	player.add_child(palm_menu)


# --- Player Seating ---
func _seat_player(player_node: Node3D) -> void:
	if not is_instance_valid(player_node):
		push_error("Player not found.")
		return

	if player_chair.has_method("seat_player"):
		player_chair.seat_player(player_node)
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
	deck_instance.scale = Vector3.ONE  # Just in case

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
