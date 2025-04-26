extends Node3D
class_name Arena

# Scenes
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")

# Instances
var deck_instance: Deck
var chairs: Array[Chair] = []

# Nodes
@onready var table_node: Node3D = $Table
@onready var player_chair: Chair = $Chairs/Chair1
@onready var player: Node3D = $Chairs/Chair1/Player

func _ready() -> void:
	chairs = [
		$Chairs/Chair1,
		$Chairs/Chair2,
		$Chairs/Chair3,
		$Chairs/Chair4
	]

	await get_tree().process_frame # Wait for full scene load

	_seat_player(player)
	_spawn_deck()
	_spawn_bots()

# --- Player Seating ---
func _seat_player(player_node: Node3D) -> void:
	if not is_instance_valid(player_node):
		push_error("Player not found.")
		return

	player_chair.seat_player(player_node)

	# Force XR rig to correct world position
	var xr_origin = player_node.get_node_or_null("XROrigin3D")
	if xr_origin:
		var chair_position = player_chair.global_transform.origin
		xr_origin.global_transform.origin = chair_position + Vector3(0, 0.4, 0)

	print("🪑 Player correctly seated and centered at Chair1.")

func get_available_chair() -> Chair:
	for chair in chairs:
		if chair and chair.is_available():
			return chair
	return null

# --- Deck Spawn ---
func _spawn_deck() -> void:
	if not deck_scene or not is_instance_valid(table_node):
		push_warning("Deck scene not assigned or table not ready.")
		return

	deck_instance = deck_scene.instantiate() as Deck
	table_node.add_child(deck_instance)

	var deck_spawn = table_node.get_node_or_null("DeckSpawnPoint")
	if deck_spawn == null:
		push_error("DeckSpawnPoint not found in table node.")
		return

	deck_instance.card_scene = preload("res://scenes/card.tscn")
	deck_instance.spawn_point_node = deck_spawn
	deck_instance.setup_deck()

	var deck_transform = deck_spawn.global_transform
	deck_transform.origin += Vector3.UP * 0.01
	deck_instance.global_transform = deck_transform

	print("✅ Deck placed at: ", deck_instance.global_transform.origin)

# --- Bot Spawn ---
func _spawn_bots() -> void:
	var bot1: Bot = bot_scene.instantiate() as Bot
	var bot2: Bot = bot_scene.instantiate() as Bot
	var bot3: Bot = bot_scene.instantiate() as Bot

	bot1.team = Bot.Team.ENEMY_TEAM
	bot2.team = Bot.Team.PLAYER_TEAM
	bot3.team = Bot.Team.ENEMY_TEAM

	# (Optional) Set difficulty here if want different bot skins
	bot1.difficulty = Bot.Difficulty.EASY
	bot2.difficulty = Bot.Difficulty.EASY
	bot3.difficulty = Bot.Difficulty.EASY

	add_child(bot1)
	add_child(bot2)
	add_child(bot3)

	_seat_bot(bot1, $Chairs/Chair2)
	_seat_bot(bot2, $Chairs/Chair3)
	_seat_bot(bot3, $Chairs/Chair4)

func _seat_bot(bot: Bot, chair: Chair) -> void:
	if not is_instance_valid(bot) or not is_instance_valid(chair):
		push_warning("❗ Bot or Chair invalid.")
		return

	chair.seat_player(bot)

	# After seating, lift the bot a bit more manually
	bot.translate(Vector3(0, 0.3, 0)) # Lift bot 0.3 meters up

	print("🤖", bot.name, "seated at", chair.name)
