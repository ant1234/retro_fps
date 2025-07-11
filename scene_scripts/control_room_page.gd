extends Control

@onready var album_button = $Panel/VBoxContainer/AlbumButton
@onready var mission_button = $Panel/VBoxContainer/MissionButton

var dialogue_started := false
var dialogue_finished := false

func _ready():
	# Disable all buttons until dialogue finishes
	album_button.disabled = true
	mission_button.disabled = true

	# Connect buttons (was missing before)
	mission_button.pressed.connect(_on_mission_pressed)
	album_button.pressed.connect(_on_album_pressed)

	# Start dialogue deferred
	call_deferred("_start_dialogue")

func _start_dialogue():
	if dialogue_started:
		return
	dialogue_started = true

	var resource = load("res://dialogue/control_room.dialogue")

	if resource and DialogueManager and DialogueManager.has_method("show_dialogue_balloon"):
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
			DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(resource, "start")
	else:
		printerr("DialogueManager missing or invalid.")

func _on_dialogue_finished(_resource = null):
	if dialogue_finished:
		return
	dialogue_finished = true

	# Disconnect signal for safety
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

	# Enable ONLY mission button
	album_button.disabled = true
	mission_button.disabled = false
	mission_button.grab_focus()
	print("Dialogue finished. Mission button now active.")

func _on_mission_pressed():
	print("Mission button pressed.")
	SceneRouter.goto_scene("res://scenes/level_select_page.tscn")

func _on_album_pressed():
	print("Album button pressed.")
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
