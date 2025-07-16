extends Node

func show_dialogue_balloon(dialogue_resource: Resource, start_node: String):
	var balloon = preload("res://ui/Dialogue_Balloon/dialogue_balloon.tscn").instantiate()

	# Loop through children and disable mouse filtering for Control nodes
	for child in balloon.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	get_tree().get_current_scene().add_child(balloon)
	balloon.start(dialogue_resource, start_node)
