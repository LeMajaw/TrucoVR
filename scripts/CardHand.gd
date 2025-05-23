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

## Assign a new set of cards to this hand
func set_cards(card_list: Array[Node3D]):
	cards = card_list
	_update_slots()

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

			# Optional freeze after positioning (prevents jitter if physics-enabled)
			if card.has_method("freeze"):
				card.freeze = true

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
	else:
		# 🔴 Just remove it from the hand
		cards.erase(card)
		card.reparent(get_tree().root)
		card.visible = true

	_update_slots() # ✅ Always called once at the end

func _get_slot_index_under(card: Node3D) -> int:
	for i in range(card_slots.size()):
		var slot = card_slots[i]
		var distance = slot.global_position.distance_to(card.global_position)
		if distance < 0.15: # 👈 adjust threshold based on scale
			return i
	return -1
