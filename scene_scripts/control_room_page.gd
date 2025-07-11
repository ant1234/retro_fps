extends Control

@onready var album_button = $Panel/VBoxContainer/AlbumButton
@onready var mission_button = $Panel/VBoxContainer/MissionButton

func _ready():
	album_button.disabled = true
	mission_button.disabled = true

	call_deferred("_start_dialogue")

func _start_dialogue():
	print("start dialogue")
	var resource = load("res://dialogue/control_room.dialogue")

	if resource and DialogueManager and DialogueManager.has_method("show_dialogue_balloon"):
		print("run dialogue")
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(resource, "start")
		print("end dialogue")
	else:
		printerr("DialogueManager is not valid or missing required methods.")
		print("Type of DialogueManager: ", typeof(DialogueManager))
		print("DialogueManager: ", DialogueManager)

func _on_dialogue_finished(_resource = null):
	album_button.disabled = false
	mission_button.disabled = false
	
func _on_mission_pressed():
	print("gets to to mission function")
	SceneRouter.goto_scene("res://scenes/level_select_page.tscn")

func _on_album_pressed():
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
