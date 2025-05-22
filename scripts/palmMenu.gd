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
@onready var truco_button: Node = $ButtonPannel/TrucoButton
@onready var config_button: Node = $ButtonPannel/ConfigButton
@onready var menu_button: Node = $ButtonPannel/MenuButton
var hand_pose_controller: Node = null

# Audio resources
var truco_sound: AudioStreamPlayer3D
var button_press_sound: AudioStreamPlayer3D

# Card state
var cards: Array[Node3D] = []
var face_down_mode: bool = false

signal truco_pressed()
signal config_pressed()
signal menu_pressed()
signal card_played(card, face_down)

func _ready() -> void:
	visible = false
	PalmMenuManager.register_menu(is_left_hand, self)
	hand_pose_controller = get_node_or_null(hand_pose_controller_path)
	
	# Setup audio
	truco_sound = AudioStreamPlayer3D.new()
	#truco_sound.stream = preload("res://assets/audio/truco_call.wav") # Ensure this asset exists
	add_child(truco_sound)
	
	button_press_sound = AudioStreamPlayer3D.new()
	#button_press_sound.stream = preload("res://assets/audio/button_press.wav") # Ensure this asset exists
	add_child(button_press_sound)
	
	# Check for Mão de 11 or Mão de Ferro
	GameManager.mao_de_11_triggered.connect(_on_mao_de_11_triggered)

func show_menu(cards_array: Array = []):
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
		if i < cards_array.size():
			slot.texture = cards_array[i]
			slot.show()

			if camera:
				var target = slot.global_transform.looking_at(camera.global_transform.origin, Vector3.UP)
				slot.global_transform = target
		else:
			slot.hide()

	visible = true
	
	# Update face down mode based on game state
	face_down_mode = GameManager.is_mao_de_11 || GameManager.is_mao_de_ferro
	_update_card_visibility()

func hide_menu():
	visible = false

func set_cards(cards_array: Array[Node3D]):
	cards = cards_array
	if card_hand:
		card_hand.set_cards(cards_array)
		if "_update_slots" in card_hand:
			card_hand.call("_update_slots")
	
	# Update face down mode based on game state
	face_down_mode = GameManager.is_mao_de_11 || GameManager.is_mao_de_ferro
	_update_card_visibility()

func _update_card_visibility():
	for card in cards:
		if face_down_mode:
			card.show_back()
		else:
			card.show_front()

func _on_button_truco_pressed(_button: Variant = null) -> void:
	print("🃏 TRUCO!")
	if truco_sound:
		truco_sound.play()
	
	# Get player index from GameManager
	var player_index = 0 # Assuming player is always index 0
	
	# Call truco in GameManager
	var success = GameManager.call_truco(player_index)
	
	if success:
		emit_signal("truco_pressed")

func _on_button_config_pressed(_button: Variant = null) -> void:
	print("⚙️ Open Configuration")
	if button_press_sound:
		button_press_sound.play()
	
	emit_signal("config_pressed")
	
	# Show configuration panel
	var config_panel = get_node_or_null("ConfigPanel")
	if config_panel:
		config_panel.visible = true

func _on_button_menu_pressed(_button: Variant = null) -> void:
	print("🏠 Open Menu")
	if button_press_sound:
		button_press_sound.play()
	
	emit_signal("menu_pressed")
	
	# Request scene change to main menu
	# This would typically be handled by a scene manager

func play_card(card: Node3D, face_down: bool = false) -> void:
	if cards.has(card):
		cards.erase(card)
		
		# Update the card hand display
		if card_hand:
			card_hand.set_cards(cards)
		
		# Emit signal for game logic to handle
		emit_signal("card_played", card, face_down)

func toggle_face_down_mode() -> void:
	face_down_mode = !face_down_mode
	_update_card_visibility()

func _on_mao_de_11_triggered(team_index: int) -> void:
	# If this is the player's team
	if team_index == 0:
		face_down_mode = true
		_update_card_visibility()
		
		# Show Mão de 11 popup
		var popup = get_node_or_null("MaoDeOnzePopup")
		if popup:
			popup.visible = true
	else:
		# For enemy team, just update the mode
		face_down_mode = true
		_update_card_visibility()

func accept_mao_de_11() -> void:
	# Player accepts Mão de 11
	GameManager.respond_to_mao_de_11(0, true)
	
	# Hide popup
	var popup = get_node_or_null("MaoDeOnzePopup")
	if popup:
		popup.visible = false

func decline_mao_de_11() -> void:
	# Player declines Mão de 11
	GameManager.respond_to_mao_de_11(0, false)
	
	# Hide popup
	var popup = get_node_or_null("MaoDeOnzePopup")
	if popup:
		popup.visible = false

# Volume control functions for config panel
func set_sfx_volume(value: float) -> void:
	# Set SFX volume (0.0 to 1.0)
	if truco_sound:
		truco_sound.volume_db = linear_to_db(value)
	
	if button_press_sound:
		button_press_sound.volume_db = linear_to_db(value)

func set_voice_chat_volume(value: float) -> void:
	# Set voice chat volume (for online mode)
	# This would connect to a voice chat system
	pass
