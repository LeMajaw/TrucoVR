extends XROrigin3D
class_name Player

@export var game_manager_path: NodePath
var hand: Array[Card] = []

@export var target_eye_height := 1.0  # Average seated eye height in meters

func _ready():
	await get_tree().process_frame  # Wait 1 frame to ensure XR data is updated
	await get_tree().process_frame  # Extra frame if needed for accuracy
	
	var camera = $XRCamera3D
	var current_y = camera.global_transform.origin.y
	
	var offset = current_y - target_eye_height
	
	# Move the entire origin down by the excess head height
	global_translate(Vector3(0, -offset, 0))

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
