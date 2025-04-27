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

func _physics_process(delta):
	time_since_last_turn += delta
	
	var forward_dir = -global_transform.basis.z
	velocity = forward_dir * swim_speed

	move_and_slide()
	
	if turn_around_on_collision and is_on_wall():
		if time_since_last_turn >= turn_cooldown:
			_turn_around_random()
			time_since_last_turn = 0.0
	
	if rotate_to_direction and velocity.length() > 0.1:
		look_at(global_transform.origin + velocity.normalized(), Vector3.UP)

func _turn_around_random():
	# Pick a random angle between 120° and 240° (to roughly reverse)
	var random_degrees = randf_range(120.0, 240.0) 
	rotate_y(deg_to_rad(random_degrees))
			 
