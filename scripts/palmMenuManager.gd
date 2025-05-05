## PalmMenuManager.gd
##
## Singleton manager to coordinate visibility of palm-up menus for left and right hands.
## Ensures that only one menu is shown at a time.

extends Node

## Reference to the left hand's PalmMenu instance (set at runtime)
var left_menu: Node = null

## Reference to the right hand's PalmMenu instance (set at runtime)
var right_menu: Node = null


## Registers a PalmMenu instance for the left or right hand
func register_menu(is_left: bool, menu: Node):
	if is_left:
		left_menu = menu
	else:
		right_menu = menu


## Shows the PalmMenu for the specified hand, and hides the other
func show_menu(is_left: bool):
	if is_left:
		if right_menu:
			right_menu.visible = false
		if left_menu:
			left_menu.visible = true
	else:
		if left_menu:
			left_menu.visible = false
		if right_menu:
			right_menu.visible = true


## Hides the PalmMenu for the specified hand (if it's visible)
func hide_menu(is_left: bool):
	if is_left and left_menu:
		left_menu.visible = false
	elif not is_left and right_menu:
		right_menu.visible = false
