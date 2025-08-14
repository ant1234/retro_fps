extends Node3D

@onready var character_mover : CharacterMover = get_parent()

@export var step_after_distance = 3.0
@onready var last_pos = global_position
var distance_travelled_since_last_step = 0.0

func _physics_process(delta: float) -> void:
	if !character_mover.character_body.is_on_floor():
		distance_travelled_since_last_step = 0.0
		
	distance_travelled_since_last_step += global_position.distance_to(last_pos)
	if distance_travelled_since_last_step >= step_after_distance:
		distance_travelled_since_last_step = 0.0
		
	last_pos = global_position
