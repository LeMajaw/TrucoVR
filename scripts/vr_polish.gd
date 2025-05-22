// VR UI Polish and Optimization Script
// This script enhances the VR experience with smoother transitions,
// better hand feedback, and optimized performance

extends Node

# Configuration
@export var enable_haptic_feedback: bool = true
@export var enable_smooth_transitions: bool = true
@export var enable_performance_optimizations: bool = true

# Haptic feedback settings
@export var card_grab_intensity: float = 0.3
@export var card_play_intensity: float = 0.5
@export var button_press_intensity: float = 0.2
@export var truco_call_intensity: float = 0.7

# Performance settings
@export var max_physics_cards: int = 10
@export var lod_distance: float = 3.0
@export var enable_dynamic_resolution: bool = true

# References
var xr_interface: XRInterface
var left_controller: XRController3D
var right_controller: XRController3D

func _ready():
	# Get XR interface
	xr_interface = XRServer.find_interface("OpenXR")
	
	# Find controllers
	left_controller = get_node_or_null("../XROrigin3D/LeftHand")
	right_controller = get_node_or_null("../XROrigin3D/RightHand")
	
	# Apply optimizations
	if enable_performance_optimizations:
		_apply_performance_optimizations()
	
	# Connect signals
	_connect_signals()
	
	print("✨ VR Polish module initialized")

func _connect_signals():
	# Connect to card signals
	var cards = get_tree().get_nodes_in_group("cards")
	for card in cards:
		if card is Card:
			if not card.card_grabbed.is_connected(_on_card_grabbed):
				card.card_grabbed.connect(_on_card_grabbed)
			
			if not card.card_played.is_connected(_on_card_played):
				card.card_played.connect(_on_card_played)
	
	# Connect to palm menu signals
	var palm_menus = get_tree().get_nodes_in_group("palm_menus")
	for menu in palm_menus:
		if menu is PalmMenu:
			if not menu.truco_pressed.is_connected(_on_truco_pressed):
				menu.truco_pressed.connect(_on_truco_pressed)
			
			if not menu.config_pressed.is_connected(_on_button_pressed):
				menu.config_pressed.connect(_on_button_pressed)
			
			if not menu.menu_pressed.is_connected(_on_button_pressed):
				menu.menu_pressed.connect(_on_button_pressed)

func _on_card_grabbed(card: Card):
	if enable_haptic_feedback:
		_trigger_haptic_pulse(card_grab_intensity, 0.1)

func _on_card_played(card: Card, _face_down: bool):
	if enable_haptic_feedback:
		_trigger_haptic_pulse(card_play_intensity, 0.2)

func _on_truco_pressed():
	if enable_haptic_feedback:
		_trigger_haptic_pulse(truco_call_intensity, 0.5)

func _on_button_pressed():
	if enable_haptic_feedback:
		_trigger_haptic_pulse(button_press_intensity, 0.1)

func _trigger_haptic_pulse(amplitude: float, duration: float):
	# Determine which controller to pulse based on proximity to the interaction
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var left_distance = 999.0
	var right_distance = 999.0
	
	if left_controller:
		left_distance = camera.global_transform.origin.distance_to(left_controller.global_transform.origin)
	
	if right_controller:
		right_distance = camera.global_transform.origin.distance_to(right_controller.global_transform.origin)
	
	# Pulse the closer controller
	if left_distance < right_distance and left_controller:
		left_controller.trigger_haptic_pulse("haptic", amplitude, duration)
	elif right_controller:
		right_controller.trigger_haptic_pulse("haptic", amplitude, duration)

func _apply_performance_optimizations():
	# Set up dynamic resolution if enabled
	if enable_dynamic_resolution and xr_interface:
		xr_interface.set_render_target_size_multiplier(0.8)
	
	# Optimize physics for cards
	var cards = get_tree().get_nodes_in_group("cards")
	var active_physics_cards = 0
	
	for card in cards:
		if card is Card:
			if active_physics_cards < max_physics_cards:
				# Keep physics enabled
				active_physics_cards += 1
			else:
				# Disable physics for distant cards
				var camera = get_viewport().get_camera_3d()
				if camera and card.global_transform.origin.distance_to(camera.global_transform.origin) > lod_distance:
					if card.has_node("XRToolsPickable"):
						card.get_node("XRToolsPickable").set_physics_process(false)
	
	# Set up LOD for distant objects
	_setup_lod()

func _setup_lod():
	# Find all meshes that could benefit from LOD
	var meshes = get_tree().get_nodes_in_group("lod_meshes")
	
	for mesh_instance in meshes:
		if mesh_instance is MeshInstance3D:
			# Create LOD levels
			mesh_instance.lod_bias = 2.0  # Higher bias means LODs change at further distances
