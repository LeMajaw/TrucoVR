extends Node3D

@onready var palm_menu = $PalmMenu
@onready var left_hand = $Hand_Left
@onready var right_hand = $Hand_Right

# Fade settings
var fade_speed := 5.0 # How fast it fades (higher = faster)
var is_menu_visible := false

func _ready() -> void:
	# Start hidden
	palm_menu.visible = false
	palm_menu.modulate.a = 0.0

func _process(delta: float) -> void:
	# Check palm orientation
	if is_palm_facing_up(left_hand) or is_palm_facing_up(right_hand):
		is_menu_visible = true
	else:
		is_menu_visible = false

	# Smooth fade
	_fade_menu(delta)

func is_palm_facing_up(hand: Node3D) -> bool:
	if not hand:
		return false

	var hand_up_vector = hand.global_transform.basis.y
	return hand_up_vector.dot(Vector3.UP) > 0.7

func _fade_menu(delta: float) -> void:
	if is_menu_visible:
		palm_menu.visible = true
		palm_menu.modulate.a = lerp(palm_menu.modulate.a, 1.0, fade_speed * delta)
	else:
		palm_menu.modulate.a = lerp(palm_menu.modulate.a, 0.0, fade_speed * delta)
		if palm_menu.modulate.a < 0.01:
			palm_menu.visible = false
