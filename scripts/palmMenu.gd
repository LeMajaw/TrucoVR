extends MeshInstance3D
class_name PalmMenu

## PalmMenu
##
## VR palm menu that shows buttons and holds a CardHand internally.
## No card logic is handled directly here anymore.

@export var is_left_hand: bool = true
@onready var card_hand := $CardHand

func _ready():
	visible = false
	PalmMenuManager.register_menu(is_left_hand, self)


func show_menu():
	visible = true

func hide_menu():
	visible = false

func set_cards(cards: Array[Node3D]):
	if card_hand:
		card_hand.set_cards(cards)

func _on_button_truco_pressed(_button: Variant) -> void:
	print("🃏 TRUCO!")

func _on_button_config_pressed(_button: Variant) -> void:
	print("⚙️ Open Configuration")

func _on_button_menu_pressed(_button: Variant) -> void:
	print("🏠 Open Menu")
