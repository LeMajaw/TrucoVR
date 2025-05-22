extends Node

## GameManager (Autoload Singleton)
##
## This script holds core references and logic for managing card distribution
## and round setup in the current game session.
## Scene nodes like the deck and hands must assign themselves on scene load.

## 🌐 Scene references (must be assigned from Arena.gd or another scene)
var deck: Deck
var player_hand: Node3D
var bot1_hand: Node3D
var bot2_hand: Node3D
var bot3_hand: Node3D
var vira_card_position: Node3D

## 🎮 Current game type
var current_game: String = "truco" # Can be expanded to "poker", etc.

var dealer_index: int = 0  # 0 = player, 1 = bot1, 2 = bot2, 3 = bot3

## 🎯 Game state tracking
var current_round_score: Dictionary = {"player_team": 0, "enemy_team": 0}
var total_score: Dictionary = {"player_team": 0, "enemy_team": 0}
var current_turn_index: int = 0  # 0 = player, 1 = bot1, 2 = bot2, 3 = bot3
var current_round_value: int = 1  # 1, 3, 6, 9, 12
var current_round_cards: Array[Card] = []
var current_round_winners: Array[int] = []  # Team indices that won each round
var is_mao_de_11: bool = false
var is_mao_de_ferro: bool = false  # 11 x 11
var last_truco_team: int = -1  # Team that last called truco

signal round_started()
signal round_ended(winning_team)
signal turn_changed(player_index)
signal score_changed(player_team_score, enemy_team_score)
signal truco_called(team_index, new_value)
signal mao_de_11_triggered(team_index)

## 🚀 Starts a new round: builds deck, draws Vira, and deals cards
func setup_round():
	if deck == null:
		push_error("❌ GameManager: Deck not assigned.")
		return

	# Reset round state
	current_round_cards.clear()
	current_round_winners.clear()
	current_round_value = 1
	last_truco_team = -1

	# Check for Mão de 11 or Mão de Ferro (11 x 11)
	is_mao_de_11 = (total_score["player_team"] == 11 and total_score["enemy_team"] < 11) or \
				  (total_score["enemy_team"] == 11 and total_score["player_team"] < 11)

	is_mao_de_ferro = total_score["player_team"] == 11 and total_score["enemy_team"] == 11

	if is_mao_de_11:
		current_round_value = 3  # Mão de 11 starts at 3 points
		var team_index = 0 if total_score["player_team"] == 11 else 1
		emit_signal("mao_de_11_triggered", team_index)

	# Reset vira reference
	CardRanks.set_vira("")

	# Set first player (after dealer)
	current_turn_index = (dealer_index + 1) % 4

	await deck.start_truco_round()
	emit_signal("round_started")
	emit_signal("turn_changed", current_turn_index)

## 🧠 Determines winner of a hand between two cards
## Returns: 1 = card1 wins, -1 = card2 wins, 0 = tie
func resolve_hand(card1: Card, card2: Card) -> int:
	var result = card1.compare_to(card2)
	if result > 0:
		print("✅ Player 1 wins the hand")
	elif result < 0:
		print("✅ Player 2 wins the hand")
	else:
		print("➖ It's a tie")

	return result

## 🎮 Play a card from a player's hand
func play_card(player_index: int, card: Card, face_down: bool = false):
	# Add card to current round
	current_round_cards.append(card)

	# If all players have played, resolve the round
	if current_round_cards.size() == 4:
		_resolve_round()
	else:
		# Move to next player
		current_turn_index = (current_turn_index + 1) % 4
		emit_signal("turn_changed", current_turn_index)

## 🏆 Resolve the current round
func _resolve_round():
	var strongest_card_index = 0
	var strongest_card = current_round_cards[0]

	# Find the strongest card
	for i in range(1, current_round_cards.size()):
		var card = current_round_cards[i]
		if resolve_hand(card, strongest_card) > 0:
			strongest_card = card
			strongest_card_index = i

	# Determine winning team (0 = player team, 1 = enemy team)
	var winning_player_index = (current_turn_index + strongest_card_index) % 4
	var winning_team = winning_player_index % 2  # 0 and 2 are player team, 1 and 3 are enemy team

	current_round_winners.append(winning_team)

	# Check if a team has won 2 rounds
	var player_team_wins = current_round_winners.count(0)
	var enemy_team_wins = current_round_winners.count(1)

	if player_team_wins >= 2 or enemy_team_wins >= 2:
		# Round is over, award points
		if player_team_wins >= 2:
			total_score["player_team"] += current_round_value
		else:
			total_score["enemy_team"] += current_round_value

		emit_signal("score_changed", total_score["player_team"], total_score["enemy_team"])
		emit_signal("round_ended", 0 if player_team_wins >= 2 else 1)

		# Check for game end
		if total_score["player_team"] >= 12 or total_score["enemy_team"] >= 12:
			_end_game()
		else:
			# Prepare for next round
			dealer_index = (dealer_index + 1) % 4
			setup_round()
	else:
		# Continue to next hand in the round
		current_round_cards.clear()
		current_turn_index = winning_player_index
		emit_signal("turn_changed", current_turn_index)

## 🏁 End the game
func _end_game():
	var winning_team = 0 if total_score["player_team"] >= 12 else 1
	print("🏆 Team " + str(winning_team) + " wins the game!")
	# Additional end game logic can be added here

## 🎲 Call truco/raise
func call_truco(player_index: int):
	var team_index = player_index % 2

	# Can't call truco twice in a row from same team
	if team_index == last_truco_team:
		return false

	var new_value = 0

	# Determine new value based on current value
	match current_round_value:
		1:
			new_value = 3  # Truco
		3:
			new_value = 6  # Seis
		6:
			new_value = 9  # Nove
		9:
			new_value = 12  # Doze
		_:
			return false  # Can't raise further

	last_truco_team = team_index
	emit_signal("truco_called", team_index, new_value)
	return true

## 🤝 Accept truco/raise
func accept_truco(new_value: int):
	current_round_value = new_value
	# Continue the game
	emit_signal("turn_changed", current_turn_index)

## 👋 Decline truco/raise
func decline_truco(team_index: int):
	# Award points to the team that called truco
	var winning_team = 1 if team_index == 0 else 0
	var team_key := "player_team" if winning_team == 0 else "enemy_team"
	total_score[team_key] += current_round_value

	emit_signal("score_changed", total_score["player_team"], total_score["enemy_team"])
	emit_signal("round_ended", winning_team)

	# Check for game end
	if total_score["player_team"] >= 12 or total_score["enemy_team"] >= 12:
		_end_game()
	else:
		# Prepare for next round
		dealer_index = (dealer_index + 1) % 4
		setup_round()

## 🎭 Handle Mão de 11 response
func respond_to_mao_de_11(team_index: int, accept: bool):
	if accept:
		# Continue with the game, already set to 3 points
		emit_signal("turn_changed", current_turn_index)
	else:
		# Award 1 point to the opposing team
		var opposing_team = 1 if team_index == 0 else 0
		var team_key := "player_team" if opposing_team == 0 else "enemy_team"
		total_score[team_key] += 1

		emit_signal("score_changed", total_score["player_team"], total_score["enemy_team"])

		# Check for game end
		if total_score["player_team"] >= 12 or total_score["enemy_team"] >= 12:
			_end_game()
		else:
			# Prepare for next round
			dealer_index = (dealer_index + 1) % 4
			setup_round()

## 🔄 Reset game for a new match
func reset_game():
	total_score = {"player_team": 0, "enemy_team": 0}
	dealer_index = 0
	is_mao_de_11 = false
	is_mao_de_ferro = false
	current_round_value = 1

	emit_signal("score_changed", 0, 0)
	setup_round()

## 🎮 Get player team index (0 for player team, 1 for enemy team)
func get_player_team(player_index: int) -> int:
	return player_index % 2
