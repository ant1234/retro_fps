extends CharacterBody3D

@export var swim_speed: float = 2.0
@export var animation_name: String = "Armature|Take 001|BaseLayer"
@export var rotate_to_direction: bool = true
@export var turn_around_on_collision: bool = true
@export var turn_cooldown: float = 1.0  # seconds

@onready var animation_player: AnimationPlayer = $Graphics/Tuna/AnimationPlayer

var time_since_last_turn: float = 999.0  # ready to turn immediately

func _ready():
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.get_animation(animation_name).loop = true
	# Initialize velocity based on current transform basis
	velocity = global_transform.basis.z * swim_speed

func _physics_process(delta):
	time_since_last_turn += delta
	
	# Move the fish using velocity vector
	move_and_slide()  # No args in Godot 4; velocity is a property
	
	if turn_around_on_collision and is_on_wall():
		if time_since_last_turn >= turn_cooldown:
			_turn_around_random()
			time_since_last_turn = 0.0
	
	if rotate_to_direction and velocity.length() > 0.1:
		var dir = velocity.normalized()
		if abs(dir.dot(Vector3.UP)) < 0.99:
			look_at(global_transform.origin + dir, Vector3.UP)

func _turn_around_random():
	var random_degrees = randf_range(120.0, 240.0)
	rotate_y(deg_to_rad(random_degrees))
	# Update velocity direction after turning
	velocity = global_transform.basis.z * swim_speed
