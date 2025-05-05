extends Node
class_name CardGameRules

## CardGameRules
##
## Provides rules and filtering for each supported game.
## Used to determine:
## - Which cards are allowed
## - The rank order for strength comparisons


# Dictionary of per-game rules
const GAME_RULES: Dictionary = {
	"truco": {
		"allowed_cards": [ # Truco uses 40 cards: no 8, 9, or 10
			"A", "2", "3", "4", "5", "6", "7", "J", "Q", "K"
		],
		"rank_order": [ # Lowest to highest (for compare logic)
			"4", "5", "6", "7", "Q", "J", "K", "A", "2", "3"
		]
	},

	"poker": {
		"allowed_cards": [ # All 52 cards allowed
			"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"
		],
		"rank_order": [ # Poker-style order
			"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"
		]
	}
}


## Checks if a card (e.g. "sK") is valid in the given game
static func is_card_allowed(card_id: String, game: String) -> bool:
	if not GAME_RULES.has(game):
		push_warning("CardGameRules: Unknown game '%s'" % game)
		return false

	var value = card_id.substr(1)
	return value in GAME_RULES[game]["allowed_cards"]


## Returns the strength rank of a card in a specific game
## Higher value = stronger card
static func get_card_rank(card_id: String, game: String) -> int:
	if not GAME_RULES.has(game):
		push_warning("CardGameRules: Unknown game '%s'" % game)
		return -1

	var value = card_id.substr(1)
	var order = GAME_RULES[game]["rank_order"]

	if not order.has(value):
		return -1

	# Strongest cards get highest score
	return order.size() - order.find(value)
