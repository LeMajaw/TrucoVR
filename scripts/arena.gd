extends Node3D
class_name Arena

# Chair placement config
@export var chair_distance: float = 1.4
@export var chair_y_offset: float = -0.75

# Runtime assignments
var table_node: Node3D
var chair_scene: PackedScene
var deck_scene: PackedScene
var deck_instance: Deck
var chairs: Array[Node3D] = []  # Store chairs for multiplayer usage

func _ready():
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		XRServer.primary_interface = xr_interface
		get_viewport().use_xr = true
		print("✅ OpenXR initialized (XR active)")
	else:
		push_warning("❗ OpenXR not initialized!")

	# ✅ Assign scenes and nodes manually
	table_node = $Table
	chair_scene = preload("res://scenes/chair.tscn")
	deck_scene = preload("res://scenes/deck.tscn")

	await get_tree().process_frame

	_place_chairs()
	await get_tree().process_frame  # Ensure chair nodes are added before seating
	_seat_player($Player)

	_spawn_deck()

func _place_chairs():
	if not chair_scene or not is_instance_valid(table_node):
		push_error("Chair scene or table node not set!")
		return

	var center = table_node.global_transform.origin

	var chair_data = [
		{ "pos": Vector3(0, 0, -chair_distance), "rot": deg_to_rad(0) },
		{ "pos": Vector3(chair_distance, 0, 0), "rot": deg_to_rad(270) },
		{ "pos": Vector3(0, 0, chair_distance), "rot": deg_to_rad(180) },
		{ "pos": Vector3(-chair_distance, 0, 0), "rot": deg_to_rad(90) }
	]

	chairs.clear()
	for data in chair_data:
		var chair = chair_scene.instantiate() as Node3D
		add_child(chair)

		var pos = center + data.pos
		pos.y += chair_y_offset
		chair.global_position = pos
		chair.rotate_y(data.rot)

		chairs.append(chair)

func _seat_player(player: Node3D):
	if not is_instance_valid(player):
		push_error("Player not found.")
		return

	var available_chair = get_available_chair()
	if available_chair and available_chair.has_method("seat_player"):
		available_chair.seat_player(player)
		print("🪑 Player seated at chair: ", available_chair.name)
	else:
		push_warning("⚠️ No available chair to seat the player.")

func get_available_chair() -> Node3D:
	for chair in chairs:
		if chair.has_method("is_available") and chair.is_available():
			return chair
	return null

func _spawn_deck():
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
