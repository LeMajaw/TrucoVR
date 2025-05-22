extends Node3D
class_name CardHand

## 📌 Slot positions for cards (max 3)
@onready var card_slots := [
	$CardSlot1,
	$CardSlot2,
	$CardSlot3
]

## 🃏 Currently held cards
var cards: Array[Node3D] = []

## Face down mode flag
var face_down_mode: bool = false

## Card played signal
signal card_played(card, face_down)
signal card_reordered()

## Assign a new set of cards to this hand
func set_cards(card_list: Array[Node3D]):
	cards = card_list
	_update_slots()
	
	# Connect card signals
	for card in cards:
		if card is Card and not card.card_played.is_connected(_on_card_played):
			card.card_played.connect(_on_card_played)

## Rearrange cards visually in the slots
func _update_slots():
	var card_count := cards.size()

	# Show all 3 slots if empty (default state)
	if card_count == 0:
		for slot in card_slots:
			slot.visible = true
		return

	# Show only the required number of slots
	for i in range(3):
		card_slots[i].visible = i < card_count

	# Position each card over its slot
	for i in range(card_count):
		if i >= card_slots.size():
			continue # prevent out-of-range errors

		var card := cards[i]
		if is_instance_valid(card):
			card.global_transform = card_slots[i].global_transform

			# Ensure grab signal is connected
			if not card.card_grabbed.is_connected(_on_card_grabbed):
				card.card_grabbed.connect(_on_card_grabbed)

			# Reparent card if needed
			if not is_instance_valid(card.get_parent()) or card.get_parent() != self:
				add_child(card)

			# Update card visibility based on face_down_mode
			if face_down_mode:
				card.show_back()
			else:
				card.show_front()

## When a card is picked from hand
func _on_card_grabbed(card: Node3D):
	if not cards.has(card):
		return

	var from_index = cards.find(card)
	var to_index = _get_slot_index_under(card)

	if to_index != -1 and to_index != from_index:
		# 🟢 Swap if dropped over a different slot
		var other_card = cards[to_index]
		cards[to_index] = card
		cards[from_index] = other_card
		emit_signal("card_reordered")
	else:
		# 🔴 Just remove it from the hand
		cards.erase(card)
		card.reparent(get_tree().root)
		card.visible = true

	_update_slots() # ✅ Always called once at the end

## When a card is played
func _on_card_played(card: Card, face_down: bool):
	if not cards.has(card):
		return
		
	# Remove card from hand
	cards.erase(card)
	_update_slots()
	
	# Forward the signal
	emit_signal("card_played", card, face_down)

func _get_slot_index_under(card: Node3D) -> int:
	for i in range(card_slots.size()):
		var slot = card_slots[i]
		var distance = slot.global_position.distance_to(card.global_position)
		if distance < 0.15: # 👈 adjust threshold based on scale
			return i
	return -1

## Set face down mode (for Mão de 11 or 11x11)
func set_face_down_mode(enabled: bool):
	face_down_mode = enabled
	_update_slots()

## Play a card at the specified index
func play_card_at_index(index: int, face_down: bool = false):
	if index < 0 or index >= cards.size():
		return
		
	var card = cards[index]
	if card is Card:
		card.play_card(face_down)
