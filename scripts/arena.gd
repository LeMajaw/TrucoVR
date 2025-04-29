extends Node3D
class_name Arena

# Scenes
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var palm_menu_scene: PackedScene = preload("res://scenes/palmMenu.tscn")

# Instances
var palm_menu_instance: MeshInstance3D
var deck_instance: Deck
var chairs: Array[Chair] = []

# Nodes
@onready var table_node: Node3D = $Table
@onready var player_chair: Chair = $Chairs/Chair1
@onready var player: Node3D = $Chairs/Chair1/Player
@onready var left_hand: Node3D = $Chairs/Chair1/Player/LeftTrackedHand
@onready var right_hand: Node3D = $Chairs/Chair1/Player/RightTrackedHand

# PalmMenu Management
var fade_speed := 5.0
var is_menu_visible := false
var attached_hand: Node3D = null
var requested_hand: Node3D = null

func _ready() -> void:
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
	_spawn_bots()

func _process(delta: float) -> void:
	_update_palm_menu(delta)

# --- Palm Menu Logic ---
func _spawn_palm_menu() -> void:
	palm_menu_instance = palm_menu_scene.instantiate() as MeshInstance3D
	add_child(palm_menu_instance)

	palm_menu_instance.visible = false

	var material: Material = palm_menu_instance.get_surface_override_material(0)
	if material and material is StandardMaterial3D:
		var mat = material as StandardMaterial3D
		mat.albedo_color.a = 0.0

func _update_palm_menu(delta: float) -> void:
	var left_up = is_palm_facing_up(left_hand)
	var right_up = is_palm_facing_up(right_hand)

	if left_up:
		requested_hand = left_hand
		is_menu_visible = true
	elif right_up:
		requested_hand = right_hand
		is_menu_visible = true
	else:
		requested_hand = null
		is_menu_visible = false

	_fade_and_switch_menu(delta)

func is_palm_facing_up(hand: Node3D) -> bool:
	if not hand:
		return false
	var hand_up_vector = hand.global_transform.basis.y
	return hand_up_vector.dot(Vector3.UP) > 0.7

func _fade_and_switch_menu(delta: float) -> void:
	if not palm_menu_instance:
		return

	var material: Material = palm_menu_instance.get_surface_override_material(0)
	if not material or not (material is StandardMaterial3D):
		return

	var mat = material as StandardMaterial3D
	var target_alpha := 1.0 if is_menu_visible else 0.0
	var target_scale := Vector3(0.6, 1.0, 0.6) if is_menu_visible else Vector3(0.01, 1.0, 0.01)

	# Animate alpha
	var current_color: Color = mat.albedo_color
	current_color.a = lerp(current_color.a, target_alpha, fade_speed * delta)
	mat.albedo_color = current_color

	# Animate scale (opening or closing)
	palm_menu_instance.scale = palm_menu_instance.scale.lerp(target_scale, fade_speed * delta)

	# Visibility control
	if is_menu_visible:
		palm_menu_instance.visible = true
		if requested_hand and attached_hand != requested_hand and mat.albedo_color.a > 0.99:
			_reattach_palm_menu(requested_hand)
	else:
		if mat.albedo_color.a < 0.01 and palm_menu_instance.scale.x < 0.02:
			palm_menu_instance.visible = false
			attached_hand = null

func _reattach_palm_menu(new_hand: Node3D) -> void:
	if not new_hand:
		return

	# Reparent
	palm_menu_instance.get_parent().remove_child(palm_menu_instance)
	new_hand.add_child(palm_menu_instance)

	# Reset transform to match palm
	palm_menu_instance.transform = Transform3D.IDENTITY
	palm_menu_instance.translation = Vector3(0, 0.15, 0)
	palm_menu_instance.rotation = Vector3.ZERO  # force no weird tilt

	attached_hand = new_hand

# --- Player Seating ---
func _seat_player(player_node: Node3D) -> void:
	if not is_instance_valid(player_node):
		push_error("Player not found.")
		return

	player_chair.seat_player(player_node)

	var xr_origin = player_node.get_node_or_null("XROrigin3D")
	if xr_origin:
		var xr_camera = xr_origin.get_node_or_null("XRCamera3D")
		if xr_camera:
			var headset_offset = xr_camera.transform.origin
			var chair_position = player_chair.global_transform.origin
			xr_origin.global_transform.origin = chair_position - headset_offset + Vector3(0, 0.4, 0)

	print("\uD83E\uDE91 Player correctly seated and aligned at Chair1.")

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

	print("✅ Deck placed at:", deck_instance.global_transform.origin)

# --- Bot Spawn ---
func _spawn_bots() -> void:
	var bot1: Bot = bot_scene.instantiate() as Bot
	var bot2: Bot = bot_scene.instantiate() as Bot
	var bot3: Bot = bot_scene.instantiate() as Bot

	bot1.team = Bot.Team.ENEMY_TEAM
	bot2.team = Bot.Team.PLAYER_TEAM
	bot3.team = Bot.Team.ENEMY_TEAM

	bot1.difficulty = Bot.Difficulty.NORMAL
	bot2.difficulty = Bot.Difficulty.HARD
	bot3.difficulty = Bot.Difficulty.EXPERT

	add_child(bot1)
	add_child(bot2)
	add_child(bot3)

	_seat_bot(bot1, $Chairs/Chair2)
	_seat_bot(bot2, $Chairs/Chair3)
	_seat_bot(bot3, $Chairs/Chair4)

func _seat_bot(bot: Bot, chair: Chair) -> void:
	if not is_instance_valid(bot) or not is_instance_valid(chair):
		push_warning("\u2757 Bot or Chair invalid.")
		return

	chair.seat_player(bot)
	bot.translate(Vector3(0, 1.2, 0))
	bot.scale = Vector3(0.35, 0.35, 0.35)

	print("\uD83E\uDD16", bot.name, "seated at", chair.name)
