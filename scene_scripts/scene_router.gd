extends Node

var current_scene: Node = null

func goto_scene(scene_path: String) -> void:
	if current_scene:
		current_scene.queue_free()

	var new_scene = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	current_scene = new_scene
