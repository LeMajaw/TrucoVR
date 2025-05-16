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

func show_menu(cards: Array = []):
	var camera := get_viewport().get_camera_3d()

	if card_hand == null:
		push_warning("🟠 card_hand not ready.")
		return

	if not card_hand.has_variable("card_slots"):
		push_warning("🟠 card_hand has no 'card_slots' variable.")
		return

	var slots: Array = card_hand.card_slots

	for i in range(slots.size()):
		var slot = slots[i]
		if i < cards.size():
			slot.texture = cards[i]
			slot.show()

			if camera:
				var target = slot.global_transform.looking_at(camera.global_transform.origin, Vector3.UP)
				slot.global_transform = target
		else:
			slot.hide()

	visible = true

func hide_menu():
	visible = false

func set_cards(cards: Array[Node3D]):
	if card_hand:
		card_hand.set_cards(cards)
		if "_update_slots" in card_hand:
			card_hand.call("_update_slots")

func _on_button_truco_pressed(_button: Variant) -> void:
	print("🃏 TRUCO!")

func _on_button_config_pressed(_button: Variant) -> void:
	print("⚙️ Open Configuration")

func _on_button_menu_pressed(_button: Variant) -> void:
	print("🏠 Open Menu")
