extends Node3D
class_name Player

@export var game_manager_path: NodePath
var hand: Array[Card] = []

func _ready():
	# Autolink GameManager if path set
	if game_manager_path:
		game_manager = get_node(game_manager_path)

var game_manager: Node = null

func draw_hand(deck: Deck):
	hand.clear()
	for i in range(3):
		var card = deck.draw_card()
		if card:
			hand.append(card)

func play_card(card: Card):
	if card in hand:
		hand.erase(card)
		if game_manager:
			game_manager.play_card(self, card)
		else:
			push_error("GameManager not linked!")

func get_vira_card() -> String:
	return hand[0].card_name.substr(1) if hand.size() > 0 else "4"
