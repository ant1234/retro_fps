extends Node3D

@export var fish_prefab: PackedScene
@export var fish_number: int = 10
@export var swim_limits: Vector3 = Vector3(10, 10, 10)
@export var fish_min_speed: float = 1.0
@export var fish_max_speed: float = 4.0
@export var neighbourhood_distance: float = 5.0
@export var rotation_speed: float = 1.0
@export var depth_level: float = 0.0 # Y-offset for vertical swim center
@export var flocking_update_rate := 4  # Higher = fewer updates per fish per second
@export var player: Node3D
@export var spawn_radius: float = 60.0
@export var despawn_radius: float = 80.0
@export var max_fish: int = 100
@export var spawn_check_interval: float = 1.0  # seconds
@export var scatter_distance: float = 10.0  # Minimum distance to submarine
@export var scatter_strength: float = 5.0   # How fast the fish scatter away


var spawn_timer := 0.0
var frame_counter := 0
var all_fish: Array = []

func _ready():
	spawn_fish()
	create_swim_limits_box()

func _physics_process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_check_interval:
		spawn_timer = 0.0
		check_proximity_spawn()

	var fish_to_remove := []

	for i in all_fish.size():
		var fish = all_fish[i]

		if player:
			var distance_to_player = fish.global_position.distance_to(player.global_position)
			if distance_to_player > despawn_radius:
				fish_to_remove.append(fish)
				continue

		# Only update flocking rules every few frames, staggered by index
		if (frame_counter + i) % flocking_update_rate == 0:
			apply_flocking_rules(fish, delta)

		move_forward(fish, delta)

	for fish in fish_to_remove:
		all_fish.erase(fish)
		fish.queue_free()

	frame_counter += 1

		
func spawn_fish_at_position(position: Vector3):
	var fish = fish_prefab.instantiate()
	fish.position = position
	fish.rotate_y(randf_range(0, TAU))
	fish.swim_speed = randf_range(fish_min_speed, fish_max_speed)

	add_child(fish)
	all_fish.append(fish)
	
func check_proximity_spawn():
	if all_fish.size() >= max_fish:
		return

	var spawn_count = min(5, max_fish - all_fish.size())
	for i in range(spawn_count):
		var offset = Vector3(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-swim_limits.y, swim_limits.y),
			randf_range(-spawn_radius, spawn_radius) 
		)
		var pos = player.global_position + offset
		spawn_fish_at_position(pos) 

func spawn_fish():
	for i in range(fish_number):
		var fish = fish_prefab.instantiate()
		
		var random_pos = Vector3(
			randf_range(-swim_limits.x, swim_limits.x),
			randf_range(-swim_limits.y, swim_limits.y) + depth_level,
			randf_range(-swim_limits.z, swim_limits.z)
		)
		fish.position = random_pos # Local position inside FlockingManager
		fish.rotate_y(randf_range(0, TAU))
		fish.swim_speed = randf_range(fish_min_speed, fish_max_speed)
		
		add_child(fish)
		all_fish.append(fish)
		
func create_swim_limits_box():
	var box = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = swim_limits * 2.0
	box.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 1, 0.0)  # Set to 0 for full transparency
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	box.material_override = material
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	box.position = Vector3(0, depth_level, 0)
	add_child(box)

func apply_flocking_rules(fish: Node3D, delta: float):
	var v_center = Vector3.ZERO
	var v_avoid = Vector3.ZERO
	var avg_speed = 0.0
	var group_size = 0
	var avg_velocity = Vector3.ZERO

	for other_fish in all_fish:
		if other_fish == fish:
			continue
		var distance = fish.position.distance_to(other_fish.position)
		if distance < neighbourhood_distance:
			v_center += other_fish.position
			avg_speed += other_fish.swim_speed
			avg_velocity += other_fish.velocity
			group_size += 1

			if distance < neighbourhood_distance / 2:
				v_avoid += (fish.position - other_fish.position)

	if group_size > 0:
		v_center /= group_size
		avg_speed /= group_size
		avg_velocity /= group_size

		var direction_to_center = (v_center - fish.position).normalized()
		var avoid_direction = v_avoid.normalized()
		var new_dir = direction_to_center + avoid_direction
		new_dir = new_dir.normalized()

		var velocity_match = avg_velocity.normalized()
		new_dir = (new_dir + velocity_match).normalized()

		# Smoothly slerp fish.velocity direction toward new_dir
		var current_velocity = fish.velocity.normalized()
		var angle_diff = current_velocity.angle_to(new_dir)
		var max_turn = rotation_speed * delta
		var turn_ratio = 1.0 if angle_diff == 0 else clamp(max_turn / angle_diff, 0, 1)
		var updated_dir = current_velocity.slerp(new_dir, turn_ratio)

		fish.velocity = updated_dir * fish.swim_speed

		# Clamp swim speed
		fish.swim_speed = clamp(avg_speed, fish_min_speed, fish_max_speed)
		fish.velocity = fish.velocity.normalized() * fish.swim_speed

	# --- Submarine avoidance / scatter ---
	if player:
		var distance_to_player = fish.global_position.distance_to(player.global_position)
		if distance_to_player < scatter_distance:
			var away_from_player = (fish.global_position - player.global_position).normalized()
			var scatter_factor = (scatter_distance - distance_to_player) / scatter_distance
			fish.velocity += away_from_player * scatter_strength * scatter_factor

	# Clamp and normalize final velocity
	fish.velocity = fish.velocity.normalized() * fish.swim_speed

	# --- Swim limits box correction ---
	var relative_pos = fish.position - Vector3(0, depth_level, 0)
	if abs(relative_pos.x) > swim_limits.x or relative_pos.y > swim_limits.y or abs(relative_pos.z) > swim_limits.z:
		var to_center = (-relative_pos).normalized()
		var current_velocity = fish.velocity.normalized()
		var angle_diff = current_velocity.angle_to(to_center)
		var max_turn = rotation_speed * delta
		var turn_ratio = 1.0 if angle_diff == 0 else clamp(max_turn / angle_diff, 0, 1)
		var new_velocity_dir = current_velocity.slerp(to_center, turn_ratio)
		fish.velocity = new_velocity_dir.normalized() * fish.swim_speed

func move_forward(fish: Node3D, delta: float):
	var new_pos = fish.position + fish.velocity * delta
	var relative_y = new_pos.y - depth_level

	var hit_top = relative_y > swim_limits.y
	var hit_bottom = relative_y < -swim_limits.y

	if hit_top or hit_bottom:
		# Reflect velocity's Y component to bounce inside Y boundary
		fish.velocity.y = -fish.velocity.y

		# Nudge position inside boundary a bit to avoid sticking
		var bounce_offset = 0.1
		if hit_top:
			new_pos.y = depth_level + swim_limits.y - bounce_offset
		else:
			new_pos.y = depth_level - swim_limits.y + bounce_offset

		# Update rotation to match new velocity direction
		var forward = fish.velocity.normalized()
		var right = Vector3.UP.cross(forward).normalized()
		var up = forward.cross(right).normalized()
		fish.transform.basis = Basis(right, up, forward)

	fish.position = new_pos
