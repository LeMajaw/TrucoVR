extends Node3D
class_name Chair

var seated_player: Node3D = null

func seat_player(player: Node3D):
	if not player:
		push_warning("❗ Tried to seat a null player.")
		return

	# First: Reparent immediately to avoid origin loss
	if player.get_parent() != self:
		player.get_parent().remove_child(player)
		self.add_child(player)

	# Reset local transform to (0,0,0)
	player.transform.origin = Vector3.ZERO

	# Now apply a manual offset AFTER reparenting
	player.translate(Vector3(0, 0.4, 0))

	# Face the table
	var table_center = get_node("/root/Arena/Table").global_transform.origin
	var look_pos = Vector3(table_center.x, player.global_transform.origin.y, table_center.z)
	player.look_at(look_pos, Vector3.UP)

	seated_player = player
	print("🪑", player.name, "seated at", self.name)


func is_available() -> bool:
	return seated_player == null or not is_instance_valid(seated_player)
