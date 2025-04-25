extends Node
class_name GameManager

@export_node_path("Node") var deck_path
@export_node_path("Node3D") var player1_hand_path
@export_node_path("Node3D") var player2_hand_path
@export_node_path("Node3D") var vira_card_position

var deck: Deck
var player1_hand: Node3D
var player2_hand: Node3D
var vira_card: Card

func _ready():
	deck = get_node(deck_path)
	player1_hand = get_node(player1_hand_path)
	player2_hand = get_node(player2_hand_path)

func setup_round():
	deck.setup_deck()

	await get_tree().process_frame # ensure deck is filled

	# 🔄 Draw Vira
	vira_card = deck.draw_card()
	vira_card.global_position = vira_card_position.global_position
	vira_card.visible = true
	vira_card.set_card(vira_card.card_name, true)

	CardRanks.set_vira(vira_card.card_name)
	print("Vira is:", vira_card.card_name)

	# 🃏 Deal 3 cards to each player
	deck.deal_cards_to_hand(player1_hand, 3)
	deck.deal_cards_to_hand(player2_hand, 3)

	# 🎮 Ready to play hands
	print("Cards dealt. Ready to play.")

# Call this when both players have played a card
func resolve_hand(card1: Card, card2: Card) -> int:
	var result = card1.compare_to(card2)
	if result > 0:
		print("Player 1 wins the hand")
	elif result < 0:
		print("Player 2 wins the hand")
	else:
		print("Tie")
	return result # 1 = P1 wins, -1 = P2 wins, 0 = tie
