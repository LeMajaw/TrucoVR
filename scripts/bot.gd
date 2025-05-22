extends Node3D
class_name Bot

# Team assignment
enum Team {
	PLAYER_TEAM,
	ENEMY_TEAM
}

# Difficulty levels
enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	EXPERT
}

# Export so you can configure them in the editor — or set from code before calling `apply_bot_appearance()`
@export var team: Team = Team.ENEMY_TEAM
@export var difficulty: Difficulty = Difficulty.EASY

# Resources
var easy_material := preload("res://resources/0_easy_material.tres")
var normal_material := preload("res://resources/1_normal_material.tres")
var hard_material := preload("res://resources/2_hard_material.tres")
var expert_material := preload("res://resources/3_expert_material.tres")
var led_red_material := preload("res://resources/led_red_material.tres")

# Pulse settings
var pulse_speed := 2.0
var pulse_amplitude := 0.5
var base_emission_energy := 0.5

var led_node: MeshInstance3D = null
var led_material_instance: StandardMaterial3D = null

# Bot AI state
var cards: Array[Card] = []
var has_played_card: bool = false
var current_round: int = 0

func _ready() -> void:
	# Don't call _apply_bot_appearance() here — let the Arena decide when
	pass

func _process(_delta: float) -> void:
	_pulse_led()

func apply_bot_appearance() -> void:
	var carcass = get_node_or_null("Sphere/Carcass")
	var led = get_node_or_null("Sphere/Led")

	if carcass:
		match difficulty:
			Difficulty.EASY:
				carcass.material_override = easy_material
			Difficulty.NORMAL:
				carcass.material_override = normal_material
			Difficulty.HARD:
				carcass.material_override = hard_material
			Difficulty.EXPERT:
				carcass.material_override = expert_material

	if led:
		led_node = led
		if team == Team.ENEMY_TEAM:
			led_material_instance = led_red_material.duplicate() as StandardMaterial3D
			led.material_override = led_material_instance
		else:
			var base_material = led.get_active_material(0)
			if base_material and base_material is StandardMaterial3D:
				led_material_instance = base_material

func _pulse_led() -> void:
	if not led_material_instance:
		return

	var time = Time.get_ticks_msec() / 1000.0
	var pulse = sin(time * pulse_speed) * pulse_amplitude + base_emission_energy
	led_material_instance.emission_energy = pulse

# Set the bot's cards
func set_cards(card_list: Array[Card]):
	cards = card_list
	has_played_card = false
	current_round = 0

# Bot AI decision making
func decide_play_card() -> Dictionary:
	# Wait a bit to simulate thinking
	await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
	
	if cards.is_empty():
		return {"card": null, "face_down": false}
	
	var card_to_play: Card = null
	var play_face_down: bool = false
	
	# Check if this is Mão de 11 or Mão de Ferro
	if GameManager.is_mao_de_11 or GameManager.is_mao_de_ferro:
		play_face_down = true
	
	# Different strategies based on difficulty
	match difficulty:
		Difficulty.EASY:
			card_to_play = _easy_strategy()
		Difficulty.NORMAL:
			card_to_play = _normal_strategy()
		Difficulty.HARD:
			card_to_play = _hard_strategy()
		Difficulty.EXPERT:
			card_to_play = _expert_strategy()
	
	# Remove the card from the bot's hand
	if card_to_play:
		cards.erase(card_to_play)
		has_played_card = true
		current_round += 1
	
	return {"card": card_to_play, "face_down": play_face_down}

# Easy difficulty: play random cards
func _easy_strategy() -> Card:
	return cards[randi() % cards.size()]

# Normal difficulty: play strongest card first
func _normal_strategy() -> Card:
	var strongest_card = cards[0]
	
	for card in cards:
		if card.get_strength() > strongest_card.get_strength():
			strongest_card = card
	
	return strongest_card

# Hard difficulty: consider round state
func _hard_strategy() -> Card:
	var round_cards = GameManager.current_round_cards
	
	# If we're first to play in the round
	if round_cards.is_empty():
		# Play a mid-strength card
		var sorted_cards = cards.duplicate()
		sorted_cards.sort_custom(func(a, b): return a.get_strength() < b.get_strength())
		
		# Play middle card
		return sorted_cards[sorted_cards.size() / 2]
	
	# If we're last to play in the round
	elif round_cards.size() == 3:
		var strongest_played = round_cards[0]
		for i in range(1, round_cards.size()):
			if round_cards[i].compare_to(strongest_played) > 0:
				strongest_played = round_cards[i]
		
		# Try to find a card that can beat the strongest
		for card in cards:
			if card.compare_to(strongest_played) > 0:
				return card
		
		# If we can't beat it, play the weakest
		var weakest_card = cards[0]
		for card in cards:
			if card.get_strength() < weakest_card.get_strength():
				weakest_card = card
		
		return weakest_card
	
	# Otherwise play a strong card
	else:
		var strongest_card = cards[0]
		for card in cards:
			if card.get_strength() > strongest_card.get_strength():
				strongest_card = card
		
		return strongest_card

# Expert difficulty: strategic play with bluffing
func _expert_strategy() -> Card:
	var round_cards = GameManager.current_round_cards
	var round_winners = GameManager.current_round_winners
	
	# First round strategy
	if current_round == 0:
		# If we're first to play
		if round_cards.is_empty():
			# 30% chance to play a strong card, 70% chance to play a mid card
			if randf() < 0.3:
				var strongest_card = cards[0]
				for card in cards:
					if card.get_strength() > strongest_card.get_strength():
						strongest_card = card
				return strongest_card
			else:
				var sorted_cards = cards.duplicate()
				sorted_cards.sort_custom(func(a, b): return a.get_strength() < b.get_strength())
				return sorted_cards[sorted_cards.size() / 2]
		else:
			# Try to win the first round
			var strongest_played = round_cards[0]
			for i in range(1, round_cards.size()):
				if round_cards[i].compare_to(strongest_played) > 0:
					strongest_played = round_cards[i]
			
			# Find a card that can beat the strongest
			for card in cards:
				if card.compare_to(strongest_played) > 0:
					return card
			
			# If we can't beat it, play the weakest
			var weakest_card = cards[0]
			for card in cards:
				if card.get_strength() < weakest_card.get_strength():
					weakest_card = card
			
			return weakest_card
	
	# Second round strategy
	elif current_round == 1:
		# If our team won the first round
		var our_team_index = team
		if round_winners.size() > 0 and round_winners[0] == our_team_index:
			# Play a strong card to secure the win
			var strongest_card = cards[0]
			for card in cards:
				if card.get_strength() > strongest_card.get_strength():
					strongest_card = card
			return strongest_card
		else:
			# We need to win this round
			if round_cards.is_empty():
				# Play our strongest
				var strongest_card = cards[0]
				for card in cards:
					if card.get_strength() > strongest_card.get_strength():
						strongest_card = card
				return strongest_card
			else:
				# Try to win the round
				var strongest_played = round_cards[0]
				for i in range(1, round_cards.size()):
					if round_cards[i].compare_to(strongest_played) > 0:
						strongest_played = round_cards[i]
				
				# Find a card that can beat the strongest
				for card in cards:
					if card.compare_to(strongest_played) > 0:
						return card
				
				# If we can't beat it, play the weakest
				var weakest_card = cards[0]
				for card in cards:
					if card.get_strength() < weakest_card.get_strength():
						weakest_card = card
				
				return weakest_card
	
	# Third round strategy - play our best remaining card
	else:
		var strongest_card = cards[0]
		for card in cards:
			if card.get_strength() > strongest_card.get_strength():
				strongest_card = card
		return strongest_card

# Decide whether to call truco
func decide_truco_call() -> bool:
	# Don't call truco if we already called it
	var our_team_index = team
	if GameManager.last_truco_team == our_team_index:
		return false
	
	var call_probability = 0.0
	
	# Different probabilities based on difficulty
	match difficulty:
		Difficulty.EASY:
			call_probability = 0.1
		Difficulty.NORMAL:
			call_probability = 0.2
		Difficulty.HARD:
			call_probability = 0.3
		Difficulty.EXPERT:
			# Expert bots consider their hand strength
			var hand_strength = _calculate_hand_strength()
			call_probability = 0.2 + (hand_strength * 0.5)
	
	return randf() < call_probability

# Decide whether to accept a truco call
func decide_accept_truco(new_value: int) -> bool:
	var accept_probability = 0.0
	
	# Different probabilities based on difficulty
	match difficulty:
		Difficulty.EASY:
			accept_probability = 0.7
		Difficulty.NORMAL:
			accept_probability = 0.6
		Difficulty.HARD:
			# Hard bots consider the new value
			accept_probability = 0.7 - (new_value * 0.05)
		Difficulty.EXPERT:
			# Expert bots consider their hand strength and the new value
			var hand_strength = _calculate_hand_strength()
			accept_probability = 0.5 + (hand_strength * 0.4) - (new_value * 0.05)
	
	return randf() < accept_probability

# Calculate the bot's hand strength (0.0 to 1.0)
func _calculate_hand_strength() -> float:
	if cards.is_empty():
		return 0.0
	
	var total_strength = 0
	var max_possible = 0
	
	for card in cards:
		total_strength += card.get_strength()
		
		# Manilhas are worth 99 points
		if card.is_manilha():
			max_possible += 99
		else:
			# Regular cards based on TRUCO_ORDER
			max_possible += 10  # Assuming 3 is worth 10 points
	
	return float(total_strength) / max_possible

# Decide whether to accept Mão de 11
func decide_accept_mao_de_11() -> bool:
	var accept_probability = 0.0
	
	# Different probabilities based on difficulty
	match difficulty:
		Difficulty.EASY:
			accept_probability = 0.8
		Difficulty.NORMAL:
			accept_probability = 0.7
		Difficulty.HARD:
			# Hard bots consider their hand strength
			var hand_strength = _calculate_hand_strength()
			accept_probability = 0.5 + (hand_strength * 0.4)
		Difficulty.EXPERT:
			# Expert bots consider their hand strength more carefully
			var hand_strength = _calculate_hand_strength()
			accept_probability = 0.4 + (hand_strength * 0.6)
	
	return randf() < accept_probability
