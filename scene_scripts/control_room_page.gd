extends Control

@onready var album_button = $Panel/VBoxContainer/AlbumButton
@onready var mission_button = $Panel/VBoxContainer/MissionButton

func _ready():
	album_button.disabled = true
	mission_button.disabled = true

	var resource = load("res://dialogue/control_room_intro.dialogue")
	DialogueManager.show_dialogue_balloon(resource, "this_is_a_node_title")

	#if not resource:
		#push_error("Failed to load dialogue resource!")
	#else:
		#print("Dialogue loaded successfully: ", resource)
#
#
	# This shows the dialogue using the default balloon system
	#DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
	#DialogueManager.show_dialogue_balloon(resource, "this_is_a_node_title")  # This matches your ~title in the .dialogue
	#

func _on_dialogue_finished(_resource = null):
	album_button.disabled = false
	mission_button.disabled = false

func _on_album_pressed():
	SceneRouter.goto_scene("res://scenes/ui/album_page.tscn")

func _on_mission_pressed():
	SceneRouter.goto_scene("res://scenes/ui/level_select_page.tscn")
