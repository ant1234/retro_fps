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

var spawn_timer := 0.0
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

	for fish in all_fish:
		var distance_to_player = fish.global_position.distance_to(player.global_position)
		if distance_to_player > despawn_radius:
			fish_to_remove.append(fish)
		else:
			apply_flocking_rules(fish, delta)
			move_forward(fish, delta)

	for fish in fish_to_remove:
		all_fish.erase(fish)
		fish.queue_free()
		
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
	var avg_velocity = Vector3.ZERO  # This will store the average velocity of the group

	for other_fish in all_fish:
		if other_fish == fish:
			continue
		var distance = fish.position.distance_to(other_fish.position)
		if distance < neighbourhood_distance:
			v_center += other_fish.position
			avg_speed += other_fish.swim_speed
			avg_velocity += -other_fish.transform.basis.z * other_fish.swim_speed  # Add to velocity sum
			group_size += 1
			
			if distance < neighbourhood_distance / 2:
				v_avoid += (fish.position - other_fish.position)

	if group_size > 0:
		v_center /= group_size
		avg_speed /= group_size
		avg_velocity /= group_size  # Calculate the average velocity of the group

		var direction_to_center = (v_center - fish.position).normalized()
		var avoid_direction = v_avoid.normalized()
		var new_dir = direction_to_center + avoid_direction
		new_dir = new_dir.normalized()

		# Now we incorporate the velocity matching (align fish direction with the average velocity)
		var velocity_match = avg_velocity.normalized()
		new_dir = (new_dir + velocity_match).normalized()  # Blend the two directions

		var current_forward = -fish.transform.basis.z
		var target_rotation = current_forward.slerp(new_dir, rotation_speed * delta)

		var basis = fish.transform.basis
		basis.z = -target_rotation
		basis = basis.orthonormalized()
		fish.transform.basis = basis

		fish.swim_speed = clamp(avg_speed, fish_min_speed, fish_max_speed)

	var relative_pos = fish.position - Vector3(0, depth_level, 0)
	if abs(relative_pos.x) > swim_limits.x or relative_pos.y > swim_limits.y or abs(relative_pos.z) > swim_limits.z:
		var to_center = (-fish.position).normalized()
		var current_forward = -fish.transform.basis.z
		var target_rotation = current_forward.slerp(to_center, rotation_speed * delta)

		var basis = fish.transform.basis
		basis.z = -target_rotation
		basis = basis.orthonormalized()
		fish.transform.basis = basis

func move_forward(fish: Node3D, delta: float):
	var forward = -fish.transform.basis.z
	fish.position += forward * fish.swim_speed * delta

	# Clamp Y so fish never go above depth_level (i.e. too close to surface)
	if fish.position.y > depth_level:
		fish.position.y = depth_level
		
	if fish.position.y < depth_level - swim_limits.y:
		fish.position.y = depth_level - swim_limits.y
