extends Control

@onready var album_button = $Panel/VBoxContainer/AlbumButton
@onready var mission_button = $Panel/VBoxContainer/MissionButton

func _ready():
	album_button.disabled = true
	mission_button.disabled = true

	mission_button.pressed.connect(_on_mission_pressed)
	album_button.pressed.connect(_on_album_pressed)

	call_deferred("_start_dialogue_if_needed")

func _start_dialogue_if_needed():
	if GameState.control_room_dialogue_shown:
		print("Dialogue already shown globally — skipping.")
		_enable_mission_button()
		return

	GameState.control_room_dialogue_shown = true
	print("Showing control room intro dialogue...")

	var resource = load("res://dialogue/control_room.dialogue")

	if resource and DialogueManager and DialogueManager.has_method("show_dialogue_balloon"):
		if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
			DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(resource, "start")
	else:
		printerr("DialogueManager missing or invalid.")

func _on_dialogue_finished(_resource = null):
	print("Dialogue finished. Enabling mission button.")

	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

	_enable_mission_button()

func _enable_mission_button():
	album_button.disabled = true
	mission_button.disabled = false
	mission_button.grab_focus()

func _on_mission_pressed():
	print("Mission button pressed.")
	SceneRouter.goto_scene("res://scenes/level_select_page.tscn")

func _on_album_pressed():
	print("Album button pressed.")
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
