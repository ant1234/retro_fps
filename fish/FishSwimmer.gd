extends CharacterBody3D

@export var swim_speed: float = 2.0
@export var animation_name: String = "Armature|Take 001|BaseLayer"
@export var rotate_to_direction: bool = true
@export var turn_around_on_collision: bool = true
@export var turn_cooldown: float = 1.0

@export var animation_player_path: NodePath
@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var time_since_last_turn: float = 999.0

func _ready():
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.get_animation(animation_name).loop = true
	else:
		push_warning("No valid AnimationPlayer or animation not found!")

	_set_initial_velocity()

func _physics_process(delta):
	time_since_last_turn += delta

	move_and_slide()  # ✅ No arguments in Godot 4

	if turn_around_on_collision and is_on_wall():
		if time_since_last_turn >= turn_cooldown:
			_turn_around_random()
			time_since_last_turn = 0.0

	if rotate_to_direction and velocity.length() > 0.1:
		var dir = velocity.normalized()

		# Skip if vertical or too small
		if dir.length() > 0.001 and abs(dir.dot(Vector3.UP)) < 0.99:
			var target = global_transform.origin + dir
			var look_dir = target - global_transform.origin

			# Skip look_at if look_dir is invalid
			if look_dir.length_squared() > 0.0001:
				var new_basis = Transform3D().looking_at(look_dir, Vector3.UP).basis.orthonormalized()

				# Only apply if determinant is valid
				if abs(new_basis.determinant()) > 0.0001:
					var new_transform = global_transform
					new_transform.basis = new_basis
					global_transform = new_transform
				else:
					push_warning("⚠️ Skipped basis assignment: determinant is zero.")
			else:
				push_warning("⚠️ Skipped look_at: target too close.")

	if abs(global_transform.basis.determinant()) < 0.001:
		global_transform.basis = Basis()  # Identity fallback

func _turn_around_random():
	var random_degrees = randf_range(120.0, 240.0)
	var new_basis = Basis(Vector3.UP, deg_to_rad(random_degrees))
	global_transform.basis = new_basis * global_transform.basis.orthonormalized()
	global_transform.basis = global_transform.basis.orthonormalized()
	_set_initial_velocity()

func _set_initial_velocity():
	velocity = global_transform.basis.z
	velocity.y *= 0.3  # ✅ Reduce vertical movement
	velocity = velocity.normalized() * swim_speed
	self.velocity = velocity  # ✅ Assign to CharacterBody3D's velocity
