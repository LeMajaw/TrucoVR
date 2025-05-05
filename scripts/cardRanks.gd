extends Node

# Truco-specific ordering and manilha logic only
const TRUCO_ORDER = ["4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"]
const SUIT_STRENGTH = {"c": 4, "h": 3, "s": 2, "d": 1}

var manilha_values: Array[String] = []
var vira_value: String = ""

func set_vira(vira_card: String):
	vira_value = vira_card.substr(1)
	var index = TRUCO_ORDER.find(vira_value)
	if index == -1:
		push_warning("Unknown vira value: %s" % vira_value)
		return

	var next_index = (index + 1) % TRUCO_ORDER.size()
	var manilha_value = TRUCO_ORDER[next_index]
	manilha_values.clear()

	for suit in ["s", "h", "d", "c"]:
		manilha_values.append("%s%s" % [suit, manilha_value])

func is_manilha(card_id: String) -> bool:
	return card_id in manilha_values

func compare_cards(card_a: String, card_b: String, game: String) -> int:
	var a_is_manilha = is_manilha(card_a)
	var b_is_manilha = is_manilha(card_b)

	if a_is_manilha and b_is_manilha:
		var a_suit = card_a.substr(0, 1)
		var b_suit = card_b.substr(0, 1)
		return SUIT_STRENGTH[a_suit] - SUIT_STRENGTH[b_suit]

	elif a_is_manilha:
		return 1
	elif b_is_manilha:
		return -1

	# Use game-specific order
	var order = CardGameRules.GAME_RULES[game]["rank_order"]
	var a_val = card_a.substr(1)
	var b_val = card_b.substr(1)

	var a_index = order.find(a_val)
	var b_index = order.find(b_val)

	if a_index == -1 or b_index == -1:
		push_warning("Unknown card values: %s vs %s" % [card_a, card_b])
		return 0

	return b_index - a_index
