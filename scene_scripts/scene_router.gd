extends Node

var current_scene: Node = null

func _ready():
	# Defer initial scene load so the scene tree is fully ready
	call_deferred("goto_scene", "res://scenes/control_room_page.tscn")

func goto_scene(scene_path: String) -> void:
	var root = get_tree().root

	if current_scene:
		# Properly remove the previous scene
		root.remove_child.call_deferred(current_scene)
		current_scene.queue_free()
		current_scene = null

	var new_scene = load(scene_path).instantiate()
	root.call_deferred("add_child", new_scene)

	# Wait one frame to ensure the scene is added before assigning current_scene
	await get_tree().process_frame
	get_tree().current_scene = new_scene
	current_scene = new_scene
