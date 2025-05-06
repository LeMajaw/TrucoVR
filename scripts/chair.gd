extends Node3D
class_name Chair

var seated_player: Node3D = null

func seat_player(player: Node3D):
	if not player:
		push_warning("❗ Tried to seat a null player.")
		return

	# Remove from previous parent and reparent
	if player.get_parent() != self:
		player.get_parent().remove_child(player)
		self.add_child(player)

	# Reset player position
	player.transform = Transform3D.IDENTITY
	player.translate(Vector3(0, 0.4, 0))  # Adjust for chair seat height

	# Look at table
	var table = get_node_or_null("/root/Arena/Table")
	if table:
		var table_pos = table.global_transform.origin
		var look_pos = Vector3(table_pos.x, player.global_transform.origin.y, table_pos.z)
		player.look_at(look_pos, Vector3.UP)
	else:
		push_warning("⚠️ Table not found for seating direction.")

	seated_player = player
	print("🪑", player.name, "seated at", self.name)
