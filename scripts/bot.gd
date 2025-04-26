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

var team: Team = Team.ENEMY_TEAM
var difficulty: Difficulty = Difficulty.EASY

@onready var skin_holder: Node3D = $Skin

func _ready() -> void:
	_apply_skin()

func _apply_skin() -> void:
	if not is_instance_valid(skin_holder):
		push_error("Skin holder node missing!")
		return

	# Remove existing skin if any
	if skin_holder.get_child_count() > 0:
		skin_holder.get_child(0).queue_free()

	# Pick the skin scene path based on difficulty
	var skin_scene_path := ""

	match difficulty:
		Difficulty.EASY:
			skin_scene_path = "res://scenes/bots/0_easy.tscn"
		Difficulty.NORMAL:
			skin_scene_path = "res://scenes/bots/1_normal.tscn"
		Difficulty.HARD:
			skin_scene_path = "res://scenes/bots/2_hard.tscn"
		Difficulty.EXPERT:
			skin_scene_path = "res://scenes/bots/3_expert.tscn"
		_:
			push_warning("Unknown difficulty, using fallback skin.")
			return

	var skin_scene = load(skin_scene_path)
	if skin_scene:
		var skin_instance = skin_scene.instantiate()
		skin_holder.add_child(skin_instance)

		# 🛠 Here's the important fix:
		skin_instance.transform.origin.y += 0.5

		print("✅ Applied skin for difficulty:", difficulty)
	else:
		push_error("Failed to load skin scene at path: " + skin_scene_path)
