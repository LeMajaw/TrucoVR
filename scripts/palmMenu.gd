extends MeshInstance3D
class_name PalmMenu

## PalmMenu
##
## VR palm menu that shows buttons and holds a CardHand internally.
## No card logic is handled directly here anymore.

@export var is_left_hand: bool = true
@export var hand_pose_controller_path: NodePath = NodePath("../HandPoseController")
@export var show_threshold: float = 0.85

@onready var card_hand: Node = $CardHand
var hand_pose_controller: Node = null

func _ready() -> void:
	visible = false
	PalmMenuManager.register_menu(is_left_hand, self)
	hand_pose_controller = get_node_or_null(hand_pose_controller_path)

func _process(_delta: float) -> void:
	if not hand_pose_controller:
		return

	var transform_hand_pose: Transform3D = hand_pose_controller.get_hand_pose_transform(0)
	var palm_normal: Vector3 = -transform_hand_pose.basis.z.normalized()
	var dot_up: float = palm_normal.dot(Vector3.UP)

	if dot_up > show_threshold:
		PalmMenuManager.show_menu(is_left_hand)
	else:
		PalmMenuManager.hide_menu(is_left_hand)

func show_menu():
	visible = true

func hide_menu():
	visible = false

func set_cards(cards: Array[Node3D]):
	if card_hand:
		card_hand.set_cards(cards)

		# Ensure cards are positioned again immediately
		if "_update_slots" in card_hand:
			card_hand.call("_update_slots")

func _on_button_truco_pressed(_button: Variant) -> void:
	print("🃏 TRUCO!")

func _on_button_config_pressed(_button: Variant) -> void:
	print("⚙️ Open Configuration")

func _on_button_menu_pressed(_button: Variant) -> void:
	print("🏠 Open Menu")
