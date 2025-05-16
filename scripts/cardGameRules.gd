extends Node
class_name CardGameRules

const GAME_RULES: Dictionary = {
	"truco": {
		"allowed_cards": [
			"4", "5", "6", "7", "queen", "jack", "king", "ace", "2", "3"
		],
		"rank_order": [
			"4", "5", "6", "7", "queen", "jack", "king", "ace", "2", "3"
		]
	},
	"poker": {
		"allowed_cards": [
			"ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king"
		],
		"rank_order": [
			"2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"
		]
	}
}

static func is_card_allowed(card_id: String, game: String) -> bool:
	if not GAME_RULES.has(game):
		push_warning("CardGameRules: Unknown game '%s'" % game)
		return false

	var parts = card_id.split("_")
	if parts.size() != 2:
		push_warning("CardGameRules: Invalid card_id format: %s" % card_id)
		return false

	var value = parts[0]
	return value in GAME_RULES[game]["allowed_cards"]

static func get_card_rank(card_id: String, game: String) -> int:
	if not GAME_RULES.has(game):
		push_warning("CardGameRules: Unknown game '%s'" % game)
		return -1

	var parts = card_id.split("_")
	if parts.size() != 2:
		push_warning("CardGameRules: Invalid card_id format: %s" % card_id)
		return -1

	var value = parts[0]
	var order = GAME_RULES[game]["rank_order"]

	if not order.has(value):
		return -1

	return order.size() - order.find(value)
