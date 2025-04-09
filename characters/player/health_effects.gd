extends Control
@onready var healed: ColorRect = $Healed
@onready var hurt: ColorRect = $Hurt
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_manager: Node3D = %HealthManager

func _ready():
	health_manager.healed.connect(on_heal)
	health_manager.damaged.connect(on_hurt)
	
func on_hurt():
	animation_player.play("flash")
	healed.hide()
	hurt.show()
	
func on_heal():
	animation_player.play("flash")
	healed.show()
	hurt.hide()
