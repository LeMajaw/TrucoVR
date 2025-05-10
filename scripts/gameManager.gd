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

## 🚀 Starts a new round: builds deck, draws Vira, and deals cards
func setup_round():
	if deck == null:
		push_error("❌ GameManager: Deck not assigned.")
		return

	# Reset vira reference
	CardRanks.set_vira("")

	await deck.start_truco_round()

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
