extends Node3D
class_name PalmMenu

@onready var truco_button = $TrucoButton
@onready var config_button = $ConfigButton
@onready var menu_button = $MenuButton

func _ready() -> void:
	truco_button.pressed.connect(_on_truco_pressed)
	config_button.pressed.connect(_on_gear_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_truco_pressed() -> void:
	print("TRUCO Called!")
	_flash_button(truco_button)

func _on_gear_pressed() -> void:
	print("Configuration Menu Opened!")
	_flash_button(config_button)

func _on_menu_pressed() -> void:
	print("Main Menu Opened!")
	_flash_button(menu_button)

func _flash_button(button: XRToolsInteractableAreaButton) -> void:
	var visual = button.get_node_or_null("MeshInstance3D")
	if not visual:
		return

	var original_color = visual.modulate
	visual.modulate = Color(0.0, 0.6, 1.0) # Bright blue flash

	# Return to normal after short delay
	await get_tree().create_timer(0.2).timeout
	visual.modulate = original_color
