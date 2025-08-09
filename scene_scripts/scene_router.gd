extends Node

signal scene_changed(new_scene_path: String)

var _current_scene_path: String = ""

func goto_scene(scene_path: String) -> void:
	# Prevent reloading the same scene
	if scene_path == _current_scene_path:
		print("Already in this scene, skipping:", scene_path)
		return

	# Store the path so we can skip next time
	_current_scene_path = scene_path

	# Try to load the new scene
	var scene_resource := load(scene_path)
	if not scene_resource:
		printerr("Failed to load scene: ", scene_path)
		return

	print("Scene loaded: ", scene_path)

	# Get the SceneTree
	var tree := get_tree()
	if not tree:
		printerr("SceneTree not found.")
		return

	# Change the scene
	var err := tree.change_scene_to_packed(scene_resource)
	if err != OK:
		printerr("Scene change failed with error code: ", err)
	else:
		print("Scene changed successfully to:", scene_path)
		emit_signal("scene_changed", scene_path)
		
func reset_current_scene():
	_current_scene_path = ""
