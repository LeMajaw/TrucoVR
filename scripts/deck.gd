extends StaticBody3D
class_name Deck

var card_scene: PackedScene
var spawn_point_node: Node3D

@onready var stack_node := $Stack

const SUITS = ["s", "h", "d", "c"]
const VALUES = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var deck: Array[Card] = []

func setup_deck():
	_generate_deck()
	_shuffle_deck()
	_position_cards()

func _generate_deck():
	deck.clear()
	for suit in SUITS:
		for value in VALUES:
			var id = "%s%s" % [suit, value]
			var card = card_scene.instantiate() as Card
			card.set_card(id, false)
			card.visible = false
			stack_node.add_child(card)
			deck.append(card)
			
			# Disable physics while stacked
			if card.has_node("RigidBody3D"):
				card.get_node("RigidBody3D").freeze = true

func _shuffle_deck():
	deck.shuffle()

func _position_cards():
	var offset_y := 0.001
	for i in deck.size():
		var card = deck[i]
		card.position = Vector3(0, i * offset_y, 0)

# ✅ Draws and returns the top card
func draw_card() -> Card:
	if deck.is_empty():
		return null

	var top_card = deck.pop_back()
	top_card.visible = true
	get_tree().current_scene.add_child(top_card)
	top_card.global_transform = spawn_point_node.global_transform.translated(Vector3(0, 0.05, 0))

	if top_card.has_node("PickableObject"):
		top_card.get_node("PickableObject").enabled = true

	# Enable physics now that it's out of the stack
	if top_card.has_node("RigidBody3D"):
		top_card.get_node("RigidBody3D").freeze = false

	return top_card

# ✅ Deals cards by showing their ID (string) to player hand
func deal_cards_to_hand(card_hand: Node3D, count: int = 3):
	if deck.size() < count:
		push_warning("Not enough cards in deck to deal.")
		return

	var dealt_ids: Array[String] = []

	for i in count:
		var card = deck.pop_back()
		dealt_ids.append(card.card_name)
		card.visible = false
		card.reparent(card_hand) # Optional: visually move them under hand

	if card_hand.has_method("show_cards"):
		card_hand.call("show_cards", dealt_ids)
