extends Node3D
class_name Bot

# Team assignment
enum Team {
	PLAYER_TEAM,
	ENEMY_TEAM
}

# Difficulty levels
enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	EXPERT
}

# Export so you can configure them in the editor — or set from code before calling `apply_bot_appearance()`
@export var team: Team = Team.ENEMY_TEAM
@export var difficulty: Difficulty = Difficulty.EASY

# Resources
var easy_material := preload("res://resources/0_easy_material.tres")
var normal_material := preload("res://resources/1_normal_material.tres")
var hard_material := preload("res://resources/2_hard_material.tres")
var expert_material := preload("res://resources/3_expert_material.tres")
var led_red_material := preload("res://resources/led_red_material.tres")

# Pulse settings
var pulse_speed := 2.0
var pulse_amplitude := 0.5
var base_emission_energy := 0.5

var led_node: MeshInstance3D = null
var led_material_instance: StandardMaterial3D = null

func _ready() -> void:
	# Don’t call _apply_bot_appearance() here — let the Arena decide when
	pass

func _process(delta: float) -> void:
	_pulse_led()

func apply_bot_appearance() -> void:
	var carcass = get_node_or_null("Sphere/Carcass")
	var led = get_node_or_null("Sphere/Led")

	if carcass:
		match difficulty:
			Difficulty.EASY:
				carcass.material_override = easy_material
			Difficulty.NORMAL:
				carcass.material_override = normal_material
			Difficulty.HARD:
				carcass.material_override = hard_material
			Difficulty.EXPERT:
				carcass.material_override = expert_material

	if led:
		led_node = led
		if team == Team.ENEMY_TEAM:
			led_material_instance = led_red_material.duplicate() as StandardMaterial3D
			led.material_override = led_material_instance
		else:
			var base_material = led.get_active_material(0)
			if base_material and base_material is StandardMaterial3D:
				led_material_instance = base_material

func _pulse_led() -> void:
	if not led_material_instance:
		return

	var time = Time.get_ticks_msec() / 1000.0
	var pulse = sin(time * pulse_speed) * pulse_amplitude + base_emission_energy
	led_material_instance.emission_energy = pulse
