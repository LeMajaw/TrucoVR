extends Node3D
class_name Card

@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var card_name: String = "" # Ex: "sA", "h7"

var front_material: StandardMaterial3D = null
var back_material: StandardMaterial3D = null
var is_face_up: bool = false

func _ready() -> void:
	var front_mesh = get_node_or_null("PickableObject/CardBody/Front")
	var back_mesh = get_node_or_null("PickableObject/CardBody/Back")

	if front_mesh and front_mesh.has_method("get_material_override"):
		front_material = front_mesh.material_override
	else:
		push_warning("⚠️ Front mesh not found or missing material override.")

	if back_mesh and back_mesh.has_method("get_material_override"):
		back_material = back_mesh.material_override
	else:
		push_warning("⚠️ Back mesh not found or missing material override.")

	_update_textures()

func set_card(id: String, face_up: bool = false) -> void:
	card_name = id
	is_face_up = face_up
	_update_textures()

func _update_textures() -> void:
	if front_material:
		front_material.albedo_texture = front_texture
	if back_material:
		back_material.albedo_texture = back_texture
	visible = is_face_up

# Get card strength for current round
func get_strength() -> int:
	if CardRanks.is_manilha(card_name):
		return 99
	else:
		var value = card_name.substr(1)
		var index = CardRanks.VALUE_ORDER.find(value)
		if index == -1:
			return 0
		return CardRanks.VALUE_ORDER.size() - index

# Compare to another card
func compare_to(other: Card) -> int:
	return CardRanks.compare_cards(card_name, other.card_name)

# Check if is Manilha
func is_manilha() -> bool:
	return CardRanks.is_manilha(card_name)
