extends Node3D
class_name Player

var hand: Array[Card] = []

func draw_hand(deck: Deck):
	hand.clear()
	for i in range(3):
		var card = deck.draw_card()
		if card:
			hand.append(card)

func play_card(card: Card):
	if card in hand:
		hand.erase(card)
		GameManager.instance.play_card(self, card)

func get_vira_card() -> String:
	return hand[0].card_name.substr(1) if hand.size() > 0 else "4"
