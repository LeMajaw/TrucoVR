extends Node3D
class_name Arena

## --- SCENES & RESOURCES ---
var bot_scene: PackedScene = preload("res://scenes/bot.tscn")
var palm_menu_scene: PackedScene = preload("res://scenes/palmMenu.tscn")
var deck_scene: PackedScene = preload("res://scenes/deck.tscn")
var player_scene: PackedScene = preload("res://scenes/player.tscn")

# Player & deck instances
var player_instance: XROrigin3D
var left_palm_menu: PalmMenu
var right_palm_menu: PalmMenu
var deck_instance: Deck

enum HandOwner {NONE = -1, LEFT = 0, RIGHT = 1}
var current_menu_owner: HandOwner = HandOwner.NONE

## --- NODEPATH EXPORTS (from second version) ---
@export var player_spawn_point: NodePath
@export var bot_spawn_points: Array[NodePath]
@export var score_display: NodePath
@export var turn_indicator: NodePath
@export var round_value_display: NodePath
@export var mao_de_11_popup: NodePath
@export var end_game_popup: NodePath

## --- SCENE NODES ---
@onready var table_node: Node3D = $Table
@onready var player_chair: Chair = $Chairs/Chair1
@onready var bot1: Node3D = $Chairs/Chair2/Bot1
@onready var bot2: Node3D = $Chairs/Chair3/Bot2
@onready var bot3: Node3D = $Chairs/Chair4/Bot3
@onready var left_hand: Node3D = null
@onready var right_hand: Node3D = null
@onready var camera: Camera3D = null

# From second version (card system)
@onready var deck_node: Deck = $Table/Deck
@onready var vira_position: Node3D = $Table/Deck/ViraSpawnPoint
@onready var player_hand: Node3D = null
@onready var bot1_hand: Node3D = $Chairs/Chair2/Bot1/CardHand
@onready var bot2_hand: Node3D = $Chairs/Chair3/Bot2/CardHand
@onready var bot3_hand: Node3D = $Chairs/Chair4/Bot3/CardHand

# UI references from second version
var bot_instances: Array[Node3D] = []
var score_display_instance: Node
var turn_indicator_instance: Node
var round_value_display_instance: Node
var mao_de_11_popup_instance: Node
var end_game_popup_instance: Node

func _ready():
	if not InputMap.has_action("menu_button"):
		InputMap.add_action("menu_button")

	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	_spawn_player()
	_spawn_palm_menus()
	_spawn_deck()
	_seat_bots()
	_setup_ui()

	player_hand = left_palm_menu.get_node("CardHand")
	GameManager.deck = deck_instance
	GameManager.player_hand = player_hand
	GameManager.bot1_hand = bot1_hand
	GameManager.bot2_hand = bot2_hand
	GameManager.bot3_hand = bot3_hand
	GameManager.vira_card_position = vira_position

	# Connect game events
	GameManager.round_started.connect(_on_round_started)
	GameManager.round_ended.connect(_on_round_ended)
	GameManager.turn_changed.connect(_on_turn_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.truco_called.connect(_on_truco_called)
	GameManager.mao_de_11_triggered.connect(_on_mao_de_11_triggered)

	GameManager.setup_round()
	await get_tree().process_frame
	seat_player_at_chair(player_chair)
func _process(_delta: float) -> void:
	var left_up := _is_palm_up(left_hand)
	var right_up := _is_palm_up(right_hand)

	match current_menu_owner:
		HandOwner.NONE:
			if left_up:
				current_menu_owner = HandOwner.LEFT
			elif right_up:
				current_menu_owner = HandOwner.RIGHT

		HandOwner.LEFT:
			if left_up:
				_check_hand_orientation(left_hand, left_palm_menu, true)
			else:
				PalmMenuManager.hide_menu(true)
				current_menu_owner = HandOwner.NONE

		HandOwner.RIGHT:
			if right_up:
				_check_hand_orientation(right_hand, right_palm_menu, false)
			else:
				PalmMenuManager.hide_menu(false)
				current_menu_owner = HandOwner.NONE

	if Input.is_action_just_pressed("menu_button"):
		print("🔁 Menu button just pressed — recentering player")
		force_absolute_player_reset()

func _is_palm_up(hand: Node3D) -> bool:
	if hand == null:
		return false
	var palm_normal = hand.global_transform.basis.z.normalized()
	return palm_normal.dot(Vector3.UP) > 0.85

func _check_hand_orientation(hand: Node3D, menu: PalmMenu, is_left: bool) -> void:
	if hand == null or menu == null:
		return

	var palm_normal = hand.global_transform.basis.z.normalized()
	var dot_up = palm_normal.dot(Vector3.UP)

	if dot_up > 0.85:
		menu.global_transform.origin = hand.global_transform.origin + palm_normal * 0.15
		var up = palm_normal
		var forward = (camera.global_transform.origin - menu.global_transform.origin).normalized()
		var right = up.cross(forward).normalized()
		forward = right.cross(up).normalized()

		menu.global_transform = Transform3D(Basis(right, up, forward), hand.global_transform.origin + palm_normal * 0.25)
		menu.rotate_object_local(Vector3.RIGHT, deg_to_rad(90))
		PalmMenuManager.show_menu(is_left)
	else:
		PalmMenuManager.hide_menu(is_left)

func _spawn_palm_menus() -> void:
	left_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	left_palm_menu.is_left_hand = true
	get_tree().current_scene.add_child(left_palm_menu)

	right_palm_menu = palm_menu_scene.instantiate() as PalmMenu
	right_palm_menu.is_left_hand = false
	get_tree().current_scene.add_child(right_palm_menu)

func _spawn_player() -> void:
	if not player_scene:
		push_error("Player scene not assigned.")
		return

	player_instance = player_scene.instantiate() as XROrigin3D
	get_tree().current_scene.add_child(player_instance)

	var chair_pos := player_chair.global_transform.origin
	var spawn_pos := chair_pos
	var _look_at := table_node.global_transform.origin
	_look_at.y = spawn_pos.y
	var _basis := Transform3D().looking_at(_look_at - spawn_pos, Vector3.UP).basis

	player_instance.global_transform = Transform3D(_basis, spawn_pos)

	if player_instance is Player:
		player_instance.table_position = table_node.global_transform.origin

	left_hand = player_instance.get_node("LeftTrackedHand")
	right_hand = player_instance.get_node("RightTrackedHand")
	camera = player_instance.get_node("XRCamera3D")

func seat_player_at_chair(chair: Chair):
	var seat_position := chair.get_node("SeatPosition") as Marker3D
	var transform := seat_position.global_transform
	transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(180))
	player_instance.global_transform = transform
	XRServer.center_on_hmd(0, false)

func force_absolute_player_reset():
	var seat_position := player_chair.get_node("SeatPosition") as Marker3D
	var transform := seat_position.global_transform
	transform.basis = transform.basis.rotated(Vector3.UP, deg_to_rad(180))
	player_instance.global_transform = transform
	XRServer.center_on_hmd(0, false)

func _spawn_deck() -> void:
	if not deck_scene or not is_instance_valid(table_node):
		push_warning("Deck scene not assigned or table not ready.")
		return

	var deck_spawn = table_node.get_node_or_null("DeckSpawnPoint")
	if deck_spawn == null:
		push_error("DeckSpawnPoint not found in table node.")
		return

	deck_instance = deck_scene.instantiate() as Deck
	get_tree().current_scene.add_child(deck_instance)
	deck_instance.global_transform = deck_spawn.global_transform.translated(Vector3.UP * 0.01)
	deck_instance.scale = Vector3.ONE
	deck_instance.spawn_point_node = deck_spawn
	deck_instance.setup_deck()

	GameManager.deck = deck_instance
	print("✅ Deck placed at:", deck_instance.global_transform.origin)

func _seat_bots() -> void:
	bot1.team = Bot.Team.ENEMY_TEAM
	bot2.team = Bot.Team.PLAYER_TEAM
	bot3.team = Bot.Team.ENEMY_TEAM

	bot1.difficulty = Bot.Difficulty.NORMAL
	bot2.difficulty = Bot.Difficulty.HARD
	bot3.difficulty = Bot.Difficulty.EXPERT

	bot1.apply_bot_appearance()
	bot2.apply_bot_appearance()
	bot3.apply_bot_appearance()

	_adjust_bot(bot1, $Chairs/Chair2)
	_adjust_bot(bot2, $Chairs/Chair3)
	_adjust_bot(bot3, $Chairs/Chair4)

func _adjust_bot(bot: Bot, chair: Chair) -> void:
	if not is_instance_valid(bot) or not is_instance_valid(chair):
		push_warning("❗ Bot or Chair invalid.")
		return

	chair.seat_player(bot)
	bot.translate(Vector3(0, 1.1, 0))
	bot.scale = Vector3(0.35, 0.35, 0.35)
	print("🤖", bot.name, "seated at", chair.name)

func _setup_ui():
	# Score display
	if has_node(score_display):
		score_display_instance = get_node(score_display)
		_update_score_display(0, 0)

	# Turn indicator
	if has_node(turn_indicator):
		turn_indicator_instance = get_node(turn_indicator)
		_update_turn_indicator(0)

	# Round value display
	if has_node(round_value_display):
		round_value_display_instance = get_node(round_value_display)
		_update_round_value_display(1)

	# Mão de 11 popup
	if has_node(mao_de_11_popup):
		mao_de_11_popup_instance = get_node(mao_de_11_popup)
		mao_de_11_popup_instance.visible = false

	# End game popup
	if has_node(end_game_popup):
		end_game_popup_instance = get_node(end_game_popup)
		end_game_popup_instance.visible = false

# --- Card Placement ---
func place_card_in_hand(card: Node3D, card_hand: Node3D, slot_index: int):
	var slot_path := "CardSlots/CardSlot%d" % (slot_index + 1)
	var card_slot := card_hand.get_node_or_null(slot_path)
	if card_slot:
		card.reparent(card_hand)
		card.global_transform = card_slot.global_transform
		if card.has_method("freeze"):
			card.freeze = true

# --- Vira Placement ---
func place_vira_card(vira_card: Node3D, deck_node: Node3D):
	vira_card.reparent(deck_node)
	vira_card.transform.origin = Vector3(0, -0.01, 0)
	vira_card.rotation_degrees = Vector3(90, 0, 0)
	if vira_card.has_method("freeze"):
		vira_card.freeze = true

# --- GameManager Signal Handlers ---
func _on_round_started():
	print("🎮 Round started")
	_update_round_value_display(GameManager.current_round_value)

func _on_round_ended(winning_team):
	print("🏁 Round ended, team %d won" % winning_team)
	var player_team_score = GameManager.total_score["player_team"]
	var enemy_team_score = GameManager.total_score["enemy_team"]
	_update_score_display(player_team_score, enemy_team_score)

	if player_team_score >= 12 or enemy_team_score >= 12:
		_show_end_game_popup(player_team_score >= 12)

func _on_turn_changed(player_index):
	print("🎯 Turn changed to player %d" % player_index)
	_update_turn_indicator(player_index)

	if player_index > 0 and player_index <= bot_instances.size():
		var bot = bot_instances[player_index - 1]
		if bot is Bot:
			if bot.decide_truco_call():
				GameManager.call_truco(player_index)
			else:
				var play_result = await bot.decide_play_card()
				if play_result.card:
					GameManager.play_card(player_index, play_result.card, play_result.face_down)

func _on_score_changed(player_team_score, enemy_team_score):
	print("📊 Score changed: Player team %d - Enemy team %d" % [player_team_score, enemy_team_score])
	_update_score_display(player_team_score, enemy_team_score)

func _on_truco_called(team_index, new_value):
	print("🃏 Team %d called truco, new value: %d" % [team_index, new_value])
	if team_index == 1:
		_show_truco_popup(new_value)
	else:
		_handle_bot_truco_response(new_value)

func _on_mao_de_11_triggered(team_index):
	print("🎭 Mão de 11 triggered for team %d" % team_index)
	if team_index == 0:
		_show_mao_de_11_popup()
	else:
		_handle_bot_mao_de_11_response(team_index)

# --- UI Update Methods ---
func _update_score_display(player_team_score, enemy_team_score):
	if score_display_instance:
		if score_display_instance.has_method("set_scores"):
			score_display_instance.set_scores(player_team_score, enemy_team_score)
		elif score_display_instance is Label:
			score_display_instance.text = "Score: %d - %d" % [player_team_score, enemy_team_score]

func _update_turn_indicator(player_index):
	if turn_indicator_instance:
		if turn_indicator_instance.has_method("set_active_player"):
			turn_indicator_instance.set_active_player(player_index)
		elif turn_indicator_instance is Label:
			var player_name = "You" if player_index == 0 else "Bot %d" % player_index
			turn_indicator_instance.text = "Turn: %s" % player_name

func _update_round_value_display(value):
	if round_value_display_instance:
		if round_value_display_instance.has_method("set_value"):
			round_value_display_instance.set_value(value)
		elif round_value_display_instance is Label:
			round_value_display_instance.text = "Round Value: %d" % value

# --- Truco Popup Simulation ---
func _show_truco_popup(new_value):
	print("🎮 Showing truco popup for value: %d" % new_value)
	await get_tree().create_timer(1.0).timeout
	GameManager.accept_truco(new_value)

func _handle_bot_truco_response(new_value):
	var responding_bot_index = (GameManager.current_turn_index + 2) % 4 - 1
	if responding_bot_index >= 0 and responding_bot_index < bot_instances.size():
		var bot = bot_instances[responding_bot_index]
		if bot is Bot:
			var accept = bot.decide_accept_truco(new_value)
			await get_tree().create_timer(1.0).timeout
			if accept:
				GameManager.accept_truco(new_value)
			else:
				GameManager.decline_truco(1)

# --- Mão de 11 Popup ---
func _show_mao_de_11_popup():
	if mao_de_11_popup_instance:
		mao_de_11_popup_instance.visible = true
		await get_tree().create_timer(2.0).timeout
		GameManager.respond_to_mao_de_11(0, true)
		mao_de_11_popup_instance.visible = false

func _handle_bot_mao_de_11_response(team_index):
	for i in range(bot_instances.size()):
		var bot = bot_instances[i]
		if bot is Bot and bot.team == team_index:
			var accept = bot.decide_accept_mao_de_11()
			await get_tree().create_timer(1.0).timeout
			GameManager.respond_to_mao_de_11(team_index, accept)
			break

# --- End Game Popup ---
func _show_end_game_popup(player_team_won):
	if end_game_popup_instance:
		var result_label = end_game_popup_instance.get_node_or_null("ResultLabel")
		if result_label:
			result_label.text = "You %s!" % ("Win" if player_team_won else "Lose")
		end_game_popup_instance.visible = true

		var rematch_button = end_game_popup_instance.get_node_or_null("RematchButton")
		var menu_button = end_game_popup_instance.get_node_or_null("MenuButton")

		if rematch_button and not rematch_button.pressed.is_connected(_on_rematch_pressed):
			rematch_button.pressed.connect(_on_rematch_pressed)

		if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
			menu_button.pressed.connect(_on_menu_pressed)

func _on_rematch_pressed():
	if end_game_popup_instance:
		end_game_popup_instance.visible = false
	GameManager.reset_game()

func _on_menu_pressed():
	print("🏠 Returning to main menu")
	GameManager.reset_game()
	if end_game_popup_instance:
		end_game_popup_instance.visible = false
