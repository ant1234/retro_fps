@tool
extends EditorPlugin

var bake_button: Button
var reset_button: Button

func _enter_tree():
	var inspector = get_editor_interface().get_inspector()
	
	# Bake / Rebake button
	bake_button = Button.new()
	bake_button.text = "Bake Chunks"
	bake_button.pressed.connect(_on_bake_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, bake_button)

	# Reset button (optional, can still be used independently)
	reset_button = Button.new()
	reset_button.text = "Reset Bake"
	reset_button.pressed.connect(_on_reset_pressed)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, reset_button)

func _exit_tree():
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, bake_button)
	remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, reset_button)

func _on_bake_pressed():
	var selection = get_editor_interface().get_selection()
	for node in selection.get_selected_nodes():
		if node is SuperChunk:
			# Reset first to ensure clean bake
			node.reset_bake()
			node._process_into_chunks()
			print("SuperChunk rebaked into chunks")

func _on_reset_pressed():
	var selection = get_editor_interface().get_selection()
	for node in selection.get_selected_nodes():
		if node is SuperChunk:
			node.reset_bake()
