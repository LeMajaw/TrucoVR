extends StaticBody3D
class_name Deck

var card_scene: PackedScene
var spawn_point_node: Node3D

@onready var stack_node := $Stack

const SUITS = ["s", "h", "d", "c"]
const VALUES = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

var deck: Array[Card] = []

func _ready():
	randomize()

func setup_deck():
	_generate_deck()
	_shuffle_deck()
	_position_cards()
	
func _generate_deck():
	deck.clear()
	for suit in SUITS:
		for value in VALUES:
			var id = "%s%s" % [suit, value]
			var card = card_scene.instantiate() as Node3D # Not RigidBody3D anymore!
			card.set_card(id, false)
			card.visible = false
			stack_node.add_child(card)
			deck.append(card)
			
			# If the card has a RigidBody3D, disable it completely
			if card.has_node("RigidBody3D"):
				var rigid = card.get_node("RigidBody3D")
				rigid.freeze = true
				rigid.sleeping = true
				rigid.set_physics_process(false)
				rigid.set_process(false)
				rigid.gravity_scale = 0.0
				rigid.linear_velocity = Vector3.ZERO
				rigid.angular_velocity = Vector3.ZERO
				# Disconnect physics manually
				rigid.physics_active = false

func _shuffle_deck():
	deck.shuffle()

func _position_cards():
	var offset_y := 0.005 # ← bigger vertical gap (was 0.003 before)
	var base_height := 0.02

	for i in deck.size():
		var card = deck[i]
		card.position = Vector3(0, base_height + i * offset_y, 0)
		card.visible = true

		# Slight random tilt (to break z-fighting)
		var random_y = randf_range(-2.0, 2.0)
		var random_x = randf_range(-0.2, 0.2) # tiny front/back tilt
		var random_z = randf_range(-0.2, 0.2) # tiny side tilt
		card.rotation_degrees = Vector3(random_x, random_y, random_z)

# ✅ Draws and returns the top card
func draw_card() -> Card:
	if deck.is_empty():
		return null

	var top_card = deck.pop_back()
	top_card.visible = true

	# Create a physics holder
	var physics_holder = RigidBody3D.new()
	physics_holder.name = "DrawnCard"
	get_tree().current_scene.add_child(physics_holder)

	# Move card under physics body
	top_card.get_parent().remove_child(top_card)
	physics_holder.add_child(top_card)
	top_card.transform = Transform3D.IDENTITY

	# Position card
	physics_holder.global_transform = spawn_point_node.global_transform.translated(Vector3(0, 0.05, 0))

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
