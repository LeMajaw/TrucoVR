extends Node3D
class_name Card

@export var card_name: String = ""

var front_material: StandardMaterial3D = null
var back_material: StandardMaterial3D = null
var is_face_up: bool = false

signal card_grabbed(card: Card)

@onready var pickable := $XRToolsPickable
@onready var front_mesh: MeshInstance3D = get_node_or_null("XRToolsPickable/CardBody/Front")
@onready var back_mesh: MeshInstance3D = get_node_or_null("XRToolsPickable/CardBody/Back")

const TEXTURE_PATH := "res://assets/card_deck/"
const BACK_TEXTURE := preload("res://assets/card_deck/background-1.jpg")
var transparent_material := preload("res://resources/transparent_material.tres")

func _ready() -> void:
	if pickable and pickable.has_signal("grabbed"):
		pickable.grabbed.connect(_on_grabbed)

	if front_mesh:
		front_material = front_mesh.material_override
		if front_material == null:
			front_material = StandardMaterial3D.new()
			front_mesh.material_override = front_material

	if back_mesh:
		back_material = back_mesh.material_override
		if back_material == null:
			back_material = StandardMaterial3D.new()
			back_mesh.material_override = back_material


	_update_textures()

func _on_grabbed(_interactor) -> void:
	emit_signal("card_grabbed", self)

func set_card(id: String, face_up: bool = false) -> void:
	card_name = id
	is_face_up = face_up
	_update_textures()

func show_front() -> void:
	is_face_up = true
	_update_textures()

func show_back() -> void:
	is_face_up = false
	_update_textures()

func _update_textures() -> void:
	if front_material and card_name != "":
		var path = TEXTURE_PATH + card_name + ".jpg"
		print("🧩 Loading card texture:", path)
		if ResourceLoader.exists(path):
			front_material.albedo_texture = load(path)
		else:
			push_warning("⚠️ Texture not found for card: " + card_name)

	if back_material:
		back_material.albedo_texture = BACK_TEXTURE

	if front_mesh:
		front_mesh.visible = is_face_up

	if back_mesh:
		back_mesh.visible = not is_face_up

	# 🔧 Ensure visibility updates correctly even after transform/basis change
	if is_inside_tree():
		if front_mesh: front_mesh.visible = is_face_up
		if back_mesh: back_mesh.visible = not is_face_up


# Game logic
func get_strength() -> int:
	var game = GameManager.current_game
	if CardRanks.is_manilha(card_name):
		return 99
	return CardGameRules.get_card_rank(card_name, game)

func compare_to(other: Card) -> int:
	var game = GameManager.current_game
	return CardRanks.compare_cards(card_name, other.card_name, game)

func is_manilha() -> bool:
	return CardRanks.is_manilha(card_name)
