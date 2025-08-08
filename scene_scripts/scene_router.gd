extends Node

var _current_scene_path: String = ""

func goto_scene(scene_path: String) -> void:
	if scene_path == _current_scene_path:
		print("Already in this scene, skipping:", scene_path)
		return

	_current_scene_path = scene_path

	var scene_resource = load(scene_path)
	if scene_resource:
		print("Scene loaded: ", scene_path)
		var tree = Engine.get_main_loop()
		if tree and tree is SceneTree:
			print("Scene tree is valid. Changing scene...")
			var err = tree.change_scene_to_packed(scene_resource)
			if err != OK:
				printerr("Scene change failed with error code: ", err)
		else:
			printerr("SceneTree not found.")
	else:
		printerr("Failed to load scene: ", scene_path)
