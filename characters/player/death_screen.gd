extends Control
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var restart_button: Button = $Panel/RestartButton

func _ready():
	restart_button.button_up.connect(restart_level)
	hide()

func show_death_screen():
	show()
	animation_player.play("fade_in")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func restart_level():
	get_tree().call_group("instanced", "queue_free")
	get_tree().reload_current_scene()
