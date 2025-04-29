extends MeshInstance3D
class_name PalmMenu

@onready var truco_button = $TrucoButton
@onready var config_button = $ConfigButton
@onready var menu_button = $MenuButton

func _ready():
	truco_button.pressed.connect(_on_truco_pressed)
	config_button.pressed.connect(_on_gear_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
   
	var card_slots = $CardSlots
	if card_slots:
		$CardSlots/CardSlot1.transform.origin = Vector3(-0.2, 0.01, 0.0)
		$CardSlots/CardSlot2.transform.origin = Vector3(0.0, 0.01, 0.0)
		$CardSlots/CardSlot3.transform.origin = Vector3(0.2, 0.01, 0.0)

	# Button layout under the cards
	$TrucoButton.transform.origin = Vector3(0.0, -0.05, 0.05)
	$ConfigButton.transform.origin = Vector3(-0.12, -0.05, 0.05)
	$MenuButton.transform.origin = Vector3(0.12, -0.05, 0.05)

	# Initial hologram-like shrink scale (used in fade animation)
	self.scale = Vector3(0.01, 1, 0.01)

	# Optional: rotate back slightly so it faces the player more
	self.rotation_degrees.x = -45


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
