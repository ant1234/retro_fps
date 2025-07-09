extends Control

@onready var name_input: LineEdit = $MainColumn/NameInput
@onready var confirm_button: Button = $MainColumn/ConfirmButton

var player_name := ""
var state := "dialogue_start"

func _ready():
	name_input.visible = false
	confirm_button.visible = false

	var resource = load("res://dialogue/id_card.dialogue")

	if resource:
		DialogueManager.dialogue_ended.connect(_on_dialogue_finished)
		DialogueManager.show_dialogue_balloon(resource, "start")
	else:
		push_error("Failed to load dialogue resource!")

	confirm_button.pressed.connect(_on_confirm_pressed)


func _on_dialogue_finished(_resource = null):
	match state:
		"dialogue_start":
			name_input.visible = true
			confirm_button.visible = true
			state = "await_name"

		"confirm_name":
			# Player confirmed name, move to next scene
			print("Name confirmed: %s" % player_name)
			GameState.player_name = player_name
			SceneRouter.goto_scene("res://scenes/ui/control_room_page.tscn")


func _on_confirm_pressed():
	match state:
		"await_name":
			var name = name_input.text.strip_edges()
			if name.is_empty():
				name_input.placeholder_text = "Please enter a valid name"
				return

			player_name = name
			GameState.player_name = name  # This sets it for dialogue interpolation via {{GameState.player_name}}

			name_input.editable = false
			name_input.visible = false
			confirm_button.visible = false

			state = "confirm_name"

			var resource = load("res://dialogue/id_card.dialogue")
			DialogueManager.show_dialogue_balloon(resource, "confirm_name")

		"confirm_name":
			pass  # Handled by dialogue choice, no button press needed
