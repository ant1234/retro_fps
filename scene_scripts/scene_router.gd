extends Node

signal scene_changed(new_scene_path: String)

var _current_scene_path: String = ""

func goto_scene(scene_path: String) -> void:
	# Avoid reloading the same scene consecutively
	if scene_path == _current_scene_path:
		print("Already in this scene, skipping:", scene_path)
		return

	_current_scene_path = scene_path

	var scene_resource := load(scene_path)
	if not scene_resource:
		printerr("Failed to load scene:", scene_path)
		return

	print("Scene loaded:", scene_path)

	var tree := get_tree()
	if not tree:
		printerr("SceneTree not found.")
		return

	var err := tree.change_scene_to_packed(scene_resource)
	if err != OK:
		printerr("Scene change failed with error code:", err)
	else:
		print("Scene changed successfully to:", scene_path)
		emit_signal("scene_changed", scene_path)

func reset_current_scene() -> void:
	# Reset the current scene path to allow reloading the same scene again
	_current_scene_path = ""
