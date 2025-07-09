extends Control

@onready var new_game_button = $ButtonContainer/NewGameButton
@onready var continue_button = $ButtonContainer/ContinueButton
@onready var options_button = $ButtonContainer/OptionsButton

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)

func _on_new_game_pressed():
	SceneRouter.goto_scene("res://scenes/ui/id_card_page.tscn")

func _on_continue_pressed():
	# TODO: Implement continue logic (load from save)
	print("Continue not implemented yet.")

func _on_options_pressed():
	# TODO: Open options menu
	print("Options not implemented yet.")
