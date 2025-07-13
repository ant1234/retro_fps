extends Node

func _ready():
	call_deferred("goto_scene", "res://scenes/camera_check_page.tscn")

func goto_scene(scene_path: String) -> void:
	var scene_resource = load(scene_path)
	if scene_resource:
		var tree = Engine.get_main_loop()
		if tree and tree is SceneTree:
			tree.change_scene_to_packed(scene_resource)
		else:
			printerr("SceneTree not found.")
	else:
		printerr("Failed to load scene: ", scene_path)
