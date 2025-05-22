extends Node

## Main Menu Manager
##
## Handles the main menu UI and navigation for the Truco Paulista VR game

@export var single_player_scene: PackedScene
@export var multiplayer_scene: PackedScene

@onready var play_online_panel = $PlayOnlinePanel
@onready var play_bots_panel = $PlayBotsPanel
@onready var config_panel = $ConfigPanel
@onready var room_code_input = $PlayOnlinePanel/RoomCodeInput
@onready var difficulty_selector = $PlayBotsPanel/DifficultySelector
@onready var sfx_volume_slider = $ConfigPanel/SFXVolumeSlider
@onready var voice_volume_slider = $ConfigPanel/VoiceVolumeSlider

# Default settings
var selected_difficulty: int = 1  # Normal difficulty
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var room_code: String = ""
var is_host: bool = false
var bot_count: int = 0
var bot_difficulties: Array[int] = [1, 1, 1]  # Default to normal difficulty

func _ready():
	# Hide all panels initially
	if play_online_panel:
		play_online_panel.visible = false
	
	if play_bots_panel:
		play_bots_panel.visible = false
	
	if config_panel:
		config_panel.visible = false
	
	# Connect button signals
	_connect_button_signals()
	
	# Load saved settings if available
	_load_settings()

func _connect_button_signals():
	# Main menu buttons
	var play_online_button = $MainPanel/PlayOnlineButton
	var play_bots_button = $MainPanel/PlayBotsButton
	var config_button = $MainPanel/ConfigButton
	
	if play_online_button:
		play_online_button.pressed.connect(_on_play_online_pressed)
	
	if play_bots_button:
		play_bots_button.pressed.connect(_on_play_bots_pressed)
	
	if config_button:
		config_button.pressed.connect(_on_config_pressed)
	
	# Play Online panel buttons
	var create_room_button = $PlayOnlinePanel/CreateRoomButton
	var join_room_button = $PlayOnlinePanel/JoinRoomButton
	var online_back_button = $PlayOnlinePanel/BackButton
	
	if create_room_button:
		create_room_button.pressed.connect(_on_create_room_pressed)
	
	if join_room_button:
		join_room_button.pressed.connect(_on_join_room_pressed)
	
	if online_back_button:
		online_back_button.pressed.connect(_on_online_back_pressed)
	
	# Play Bots panel buttons
	var start_game_button = $PlayBotsPanel/StartGameButton
	var bots_back_button = $PlayBotsPanel/BackButton
	
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_pressed)
	
	if bots_back_button:
		bots_back_button.pressed.connect(_on_bots_back_pressed)
	
	# Config panel buttons
	var config_save_button = $ConfigPanel/SaveButton
	var config_back_button = $ConfigPanel/BackButton
	
	if config_save_button:
		config_save_button.pressed.connect(_on_config_save_pressed)
	
	if config_back_button:
		config_back_button.pressed.connect(_on_config_back_pressed)
	
	# Difficulty selector
	if difficulty_selector:
		difficulty_selector.item_selected.connect(_on_difficulty_selected)
	
	# Volume sliders
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	
	if voice_volume_slider:
		voice_volume_slider.value_changed.connect(_on_voice_volume_changed)
	
	# Bot count and difficulty selectors
	var add_bot_button = $PlayOnlinePanel/AddBotButton
	var remove_bot_button = $PlayOnlinePanel/RemoveBotButton
	var bot_difficulty_selector = $PlayOnlinePanel/BotDifficultySelector
	
	if add_bot_button:
		add_bot_button.pressed.connect(_on_add_bot_pressed)
	
	if remove_bot_button:
		remove_bot_button.pressed.connect(_on_remove_bot_pressed)
	
	if bot_difficulty_selector:
		bot_difficulty_selector.item_selected.connect(_on_bot_difficulty_selected)

func _on_play_online_pressed():
	# Show Play Online panel
	if play_online_panel:
		play_online_panel.visible = true
	
	# Hide other panels
	if play_bots_panel:
		play_bots_panel.visible = false
	
	if config_panel:
		config_panel.visible = false

func _on_play_bots_pressed():
	# Show Play Bots panel
	if play_bots_panel:
		play_bots_panel.visible = true
	
	# Hide other panels
	if play_online_panel:
		play_online_panel.visible = false
	
	if config_panel:
		config_panel.visible = false

func _on_config_pressed():
	# Show Config panel
	if config_panel:
		config_panel.visible = true
	
	# Hide other panels
	if play_online_panel:
		play_online_panel.visible = false
	
	if play_bots_panel:
		play_bots_panel.visible = false

func _on_create_room_pressed():
	is_host = true
	room_code = _generate_room_code()
	
	# Display room code
	var room_code_display = $PlayOnlinePanel/RoomCodeDisplay
	if room_code_display:
		room_code_display.text = "Room Code: " + room_code
	
	# Start multiplayer game
	_start_multiplayer_game()

func _on_join_room_pressed():
	is_host = false
	
	# Get room code from input
	if room_code_input:
		room_code = room_code_input.text
	
	# Start multiplayer game
	_start_multiplayer_game()

func _on_online_back_pressed():
	# Hide Play Online panel
	if play_online_panel:
		play_online_panel.visible = false

func _on_start_game_pressed():
	# Start single player game with bots
	_start_single_player_game()

func _on_bots_back_pressed():
	# Hide Play Bots panel
	if play_bots_panel:
		play_bots_panel.visible = false

func _on_config_save_pressed():
	# Save settings
	_save_settings()
	
	# Hide Config panel
	if config_panel:
		config_panel.visible = false

func _on_config_back_pressed():
	# Discard changes and hide Config panel
	_load_settings()
	
	if config_panel:
		config_panel.visible = false

func _on_difficulty_selected(index):
	selected_difficulty = index

func _on_sfx_volume_changed(value):
	sfx_volume = value
	
	# Update audio bus
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_voice_volume_changed(value):
	voice_volume = value
	
	# Update audio bus
	var bus_index = AudioServer.get_bus_index("Voice")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_add_bot_pressed():
	if bot_count < 3:
		bot_count += 1
		
		# Update bot count display
		var bot_count_display = $PlayOnlinePanel/BotCountDisplay
		if bot_count_display:
			bot_count_display.text = "Bots: " + str(bot_count)

func _on_remove_bot_pressed():
	if bot_count > 0:
		bot_count -= 1
		
		# Update bot count display
		var bot_count_display = $PlayOnlinePanel/BotCountDisplay
		if bot_count_display:
			bot_count_display.text = "Bots: " + str(bot_count)

func _on_bot_difficulty_selected(index):
	# Set difficulty for all bots
	for i in range(bot_difficulties.size()):
		bot_difficulties[i] = index

func _start_single_player_game():
	if single_player_scene:
		# Store settings for the game scene to access
		_store_game_settings()
		
		# Change to the single player scene
		get_tree().change_scene_to_packed(single_player_scene)

func _start_multiplayer_game():
	if multiplayer_scene:
		# Store settings for the game scene to access
		_store_game_settings()
		
		# Change to the multiplayer scene
		get_tree().change_scene_to_packed(multiplayer_scene)

func _generate_room_code() -> String:
	# Generate a random 6-character room code
	var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	
	for i in range(6):
		var random_index = randi() % characters.length()
		code += characters[random_index]
	
	return code

func _store_game_settings():
	# Store settings in an autoload singleton or user data
	var settings = {
		"difficulty": selected_difficulty,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume,
		"is_multiplayer": is_host or room_code != "",
		"is_host": is_host,
		"room_code": room_code,
		"bot_count": bot_count,
		"bot_difficulties": bot_difficulties
	}
	
	# Save to user data
	var file = FileAccess.open("user://game_settings.dat", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func _save_settings():
	# Save settings to user data
	var settings = {
		"difficulty": selected_difficulty,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume
	}
	
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func _load_settings():
	# Load settings from user data
	var file = FileAccess.open("user://settings.dat", FileAccess.READ)
	if file:
		var settings = file.get_var()
		file.close()
		
		if settings is Dictionary:
			if settings.has("difficulty"):
				selected_difficulty = settings.difficulty
				
				if difficulty_selector:
					difficulty_selector.selected = selected_difficulty
			
			if settings.has("sfx_volume"):
				sfx_volume = settings.sfx_volume
				
				if sfx_volume_slider:
					sfx_volume_slider.value = sfx_volume
				
				# Update audio bus
				var sfx_bus_index = AudioServer.get_bus_index("SFX")
				if sfx_bus_index >= 0:
					AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))
			
			if settings.has("voice_volume"):
				voice_volume = settings.voice_volume
				
				if voice_volume_slider:
					voice_volume_slider.value = voice_volume
				
				# Update audio bus
				var voice_bus_index = AudioServer.get_bus_index("Voice")
				if voice_bus_index >= 0:
					AudioServer.set_bus_volume_db(voice_bus_index, linear_to_db(voice_volume))
