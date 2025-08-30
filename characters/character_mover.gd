class_name CharacterMover extends Node3D
@onready var submarine_player: CharacterBody3D = $".."

@export var jump_force = 15.0
@export var gravity = 30.0

@export var max_speed = 15.0
@export var move_accel = 4.0
@export var stop_drag = 0.9

# Water movement 
@export var swim_up_speed := 10.0
var cam_aligned_wish_dir := Vector3.ZERO
var camera_3d = null

var character_body : CharacterBody3D
var move_drag = 0.0
var move_dir : Vector3
var in_water := false

signal moved(velocity: Vector3, grounded: bool)

func _ready() -> void:
	character_body = get_parent()
	move_drag = float(move_accel) / max_speed
	if has_node("../Camera3D"):
		camera_3d = get_node("../Camera3D") as Camera3D
	

func set_move_dir(new_move_dir: Vector3):
	move_dir = new_move_dir
	move_dir.y = 0.0
	move_dir = move_dir.normalized()


func get_move_speed() -> float:
	return max_speed / 2.0 if in_water else max_speed
	
func jump():
	if character_body.is_on_floor():
		if has_node("JumpSound"):
			$JumpSound.play()
		character_body.velocity.y = jump_force

func _is_in_water() -> bool:
	# Determine if currently overlapping any water areas
	for area in get_tree().get_nodes_in_group("water_area"):
		if area.overlaps_body(submarine_player):
			return true
	return false

func _physics_process(delta: float) -> void:
	in_water = _is_in_water()
	
	# Handle water and land movement
	if in_water:
		character_body.velocity += move_dir * get_move_speed() * delta

		if Input.is_action_pressed("jump"):
			character_body.velocity.y += swim_up_speed * delta
		else:
			character_body.velocity.y -= gravity * 0.01 * delta

		character_body.velocity.x = lerp(character_body.velocity.x, 0.0, 1.5 * delta)
		character_body.velocity.z = lerp(character_body.velocity.z, 0.0, 1.5 * delta)

	else:
		if character_body.velocity.y > 0.0 and character_body.is_on_ceiling():
			character_body.velocity.y = 0.0
		if not character_body.is_on_floor():
			character_body.velocity.y -= gravity * delta

		var drag = move_drag if not move_dir.is_zero_approx() else stop_drag
		var flat_velo = character_body.velocity
		flat_velo.y = 0.0
		character_body.velocity += move_accel * move_dir - flat_velo * drag

	# --- Custom multi-collision sliding ---
	var motion = character_body.velocity * delta
	var max_slides = 4
	var remaining_motion = motion

	for i in range(max_slides):
		var collision = character_body.move_and_collide(remaining_motion)
		if not collision:
			break

		# Slide along collision
		remaining_motion = collision.get_remainder()
		character_body.velocity = character_body.velocity.slide(collision.get_normal())

		# Prevent wall-climbing: block upward velocity unless jump pressed
		if character_body.velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			character_body.velocity.y = 0.0

	moved.emit(character_body.velocity, character_body.is_on_floor())
