@tool
extends Node3D
class_name PlayerManager

@export var player_scenes: PlayerSceneListResource
@export var default_player_index: int = 0

var player_root: NodePath = NodePath("PlayerRoot")
var current_player: Node = null

# Called when the node enters the scene tree
func _ready():
	if player_scenes:
		default_player_index = clamp(default_player_index, 0, max(player_scenes.scenes.size() - 1, 0))
		_spawn_player(default_player_index)
		_highlight_block(default_player_index)

func cycle_player_scene():
	if not player_scenes or player_scenes.scenes.is_empty():
		return
	default_player_index = (default_player_index + 1) % player_scenes.scenes.size()
	_spawn_player(default_player_index)
	_highlight_block(default_player_index)

func _spawn_player(index: int):
	var root = get_node_or_null(player_root)
	if not root:
		push_error("Player root path is invalid or not set!")
		return

	if current_player and current_player.is_inside_tree():
		current_player.queue_free()
		current_player = null

	if index >= 0 and index < player_scenes.scenes.size():
		var scene = player_scenes.scenes[index]
		if scene:
			current_player = scene.instantiate()
			root.add_child(current_player)

	# Set highlight color for the corresponding block
	_highlight_block(index)

	if current_player:
		print("Spawned player:", player_scenes.scenes[index].resource_path.get_file())

func _unhandled_input(event):
	if event.is_action_pressed("cycle_player"):
		cycle_player_scene()

func _highlight_block(index: int):
	var blocks_node = get_node("/root/Main/Blocks")
	if not blocks_node:
		push_error("Blocks node not found!")
		return

	for i in blocks_node.get_child_count():
		var block = blocks_node.get_child(i)
		var mesh_instance := block.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			var mat: StandardMaterial3D = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
			if mat == null:
				mat = StandardMaterial3D.new()
				mesh_instance.set_surface_override_material(0, mat)

			mat.albedo_color = Color(0, 1, 0) if i == index else Color(1, 1, 1)
