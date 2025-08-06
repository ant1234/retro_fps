extends Control

@onready var mission_button: Button = $Panel/VBoxContainer/MissionButton
@onready var album_button: Button = $Panel/VBoxContainer/AlbumButton

func _ready():
	album_button.disabled = true
	mission_button.disabled = true

	mission_button.pressed.connect(_on_mission_pressed)
	album_button.pressed.connect(_on_album_pressed)

	call_deferred("_start_dialogue_if_needed")

func _start_dialogue_if_needed():
	var resource = load("res://dialogue/control_room.dialogue")

	if not resource or not DialogueManager or not DialogueManager.has_method("show_dialogue_balloon"):
		printerr("DialogueManager missing or invalid.")
		_enable_mission_button()
		return

	# If coming back from totals page
	if GameState.returning_from_totals:
		GameState.returning_from_totals = false
		print("Showing post-evaluation dialogue...")
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(resource, "post_evaluation")
		return

	# If intro dialogue already shown, skip
	if GameState.control_room_dialogue_shown:
		print("Intro dialogue already shown — skipping.")
		_enable_mission_button()
		return

	# First-time control room intro
	GameState.control_room_dialogue_shown = true
	print("Showing control room intro dialogue...")
	DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
	DialogueManager.show_dialogue_balloon(resource, "start")
	
func go_to_stage():
	SceneRouter.goto_scene("res://scenes/level_select_page.tscn")

func _on_dialogue_finished(_resource = null):
	print("Dialogue finished. Will enable mission button after delay.")

	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_finished):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_finished)

	await get_tree().create_timer(0.3).timeout
	_enable_mission_button()

func _enable_mission_button():
	album_button.disabled = true
	mission_button.disabled = false
	print("Mission button enabled.")

func _on_mission_pressed():
	print("Mission button pressed.")
	SceneRouter.goto_scene("res://scenes/level_select_page.tscn")

func _on_album_pressed():
	print("Album button pressed.")
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
