extends Control

@onready var mark_button = $Panel/VBoxContainer/MarkPage
@onready var control_room_button = $Panel/VBoxContainer/ToControlRoom

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# ✅ Set game_states immediately, just like evaluation_page.gd
	DialogueManager.game_states.clear()
	DialogueManager.game_states.append(self)
	DialogueManager.game_states.append(GameState)

	DialogueManager.dialogue_ended.connect(to_album_page)
	
	# Disable buttons initially
	mark_button.disabled = true
	control_room_button.disabled = true

	call_deferred("_count_photos_and_show_dialogue")

func _count_photos_and_show_dialogue():
	var count := 0
	var meta_dir := DirAccess.open("user://photo_json")

	if meta_dir:
		meta_dir.list_dir_begin()
		var file_name = meta_dir.get_next()
		while file_name != "":
			if !meta_dir.current_is_dir() and file_name.ends_with(".json"):
				count += 1
			file_name = meta_dir.get_next()
		meta_dir.list_dir_end()
	else:
		printerr("Could not access user://photo_json")

	GameState.photo_count = count

	# Reset game_states again before showing dialogue
	DialogueManager.game_states.clear()
	DialogueManager.game_states.append({"self": self})
	DialogueManager.game_states.append({"GameState": GameState})

	var dialogue_resource = load("res://dialogue/camera_check.dialogue")
	if dialogue_resource and DialogueManager:
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	else:
		printerr("DialogueManager missing or failed to load dialogue.")

func _on_dialogue_finished(_resource = null):
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

	# Re-enable the buttons after dialogue ends
	mark_button.disabled = false
	control_room_button.disabled = false
	
func to_album_page(resource = null):
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
