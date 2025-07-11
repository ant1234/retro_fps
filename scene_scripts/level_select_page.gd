extends Control

@onready var stage1_button: Button = $Panel/VBoxContainer/Stage1Button
@onready var return_button: Button = $Panel/VBoxContainer/Return
@onready var map_preview: TextureRect = $MapPreview

var dialogue_resource: Resource
var pending_decision := false

func _ready():
	dialogue_resource = load("res://dialogue/level_select.dialogue")

	stage1_button.pressed.connect(func():
		_on_stage_selected("Stage 1")
	)

	return_button.pressed.connect(_on_return_pressed)

	DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

func _on_stage_selected(stage_name: String):
	GameState.selected_stage = stage_name
	GameState.confirmed_stage = false
	pending_decision = true

	DialogueManager.show_dialogue_balloon(dialogue_resource, "stage_prompt")

func _on_dialogue_finished(_resource):
	if pending_decision:
		if GameState.confirmed_stage:
			match GameState.selected_stage:
				"Stage 1":
					SceneRouter.goto_scene("res://world.tscn")
				_:
					print("Unhandled stage: ", GameState.selected_stage)
		else:
			print("Player cancelled selection.")
		pending_decision = false

func _on_return_pressed():
	SceneRouter.goto_scene("res://scenes/control_room_page.tscn")
	
func _exit_tree():
	print("Exited scene: ", self.name)
