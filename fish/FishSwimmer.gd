extends CharacterBody3D

@export var swim_speed: float = 2.0
@export var animation_name: String = "Armature|Take 001|BaseLayer"
@export var rotate_to_direction: bool = true
@export var turn_around_on_collision: bool = true
@export var turn_cooldown: float = 1.0

@export var animation_player_path: NodePath
@export var scatter_distance: float = 10.0      # distance from player before scattering
@export var scatter_strength: float = 2.0       # how strong the scatter push is
@export var scatter_radius: float = 12.0        # how far panic spreads to other fish
@export var scatter_duration: float = 3.0       # how long before calming down

@onready var animation_player: AnimationPlayer = get_node_or_null(animation_player_path)

var time_since_last_turn: float = 999.0
var player: Node3D = null  # will cache the submarine player dynamically
var is_scattering: bool = false

func _ready():
	add_to_group("fish")  

	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)
		animation_player.get_animation(animation_name).loop = true
	else:
		push_warning("No valid AnimationPlayer or animation not found!")

	_set_initial_velocity()

func _physics_process(delta):
	time_since_last_turn += delta

	# --- find player if not yet cached ---
	if player == null:
		player = get_tree().get_first_node_in_group("player")  # assumes submarine has "player" group

	# --- Submarine avoidance / scatter ---
	if player and not is_scattering:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < scatter_distance:
			_scatter()

	move_and_slide()  # Godot 4

	if turn_around_on_collision and is_on_wall():
		if time_since_last_turn >= turn_cooldown:
			_turn_around_random()
			time_since_last_turn = 0.0

	if rotate_to_direction and velocity.length() > 0.1:
		var dir = velocity.normalized()

		if dir.length() > 0.001 and abs(dir.dot(Vector3.UP)) < 0.99:
			var target = global_transform.origin + dir
			var look_dir = target - global_transform.origin

			if look_dir.length_squared() > 0.0001:
				var new_basis = Transform3D().looking_at(look_dir, Vector3.UP).basis.orthonormalized()
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

func _scatter():
	if is_scattering:
		return
	is_scattering = true

	# --- Move away from player ---
	if player:
		var away_from_player = (global_position - player.global_position).normalized()
		velocity = away_from_player * scatter_strength

	# --- Trigger nearby fish in group ---
	for fish in get_tree().get_nodes_in_group("fish"):
		if fish == self:
			continue
		if fish.global_position.distance_to(global_position) < scatter_radius:
			fish._scatter()

	# --- Calm down after a delay ---
	await get_tree().create_timer(scatter_duration).timeout
	is_scattering = false
	# Return to normal swimming speed
	velocity = velocity.normalized() * swim_speed

func _turn_around_random():
	var random_degrees = randf_range(120.0, 240.0)
	var new_basis = Basis(Vector3.UP, deg_to_rad(random_degrees))
	global_transform.basis = new_basis * global_transform.basis.orthonormalized()
	global_transform.basis = global_transform.basis.orthonormalized()
	_set_initial_velocity()

func _set_initial_velocity():
	velocity = global_transform.basis.z
	velocity.y *= 0.3  
	velocity = velocity.normalized() * swim_speed
	self.velocity = velocity
