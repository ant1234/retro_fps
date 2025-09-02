# WorldManager.gd
extends Node3D

@export var player_path: NodePath   # drag your Player node here
@export var chunk_size: Vector3 = Vector3(20, 20, 20)
@export var chunk_scene: PackedScene
@export var view_distance: int = 1  # how many chunks in each direction
@export var remove_margin: int = 2  # buffer to prevent oscillation
@export var max_removals_per_frame: int = 5  # limit removals per frame for stability

var player: Node3D
var chunks: Dictionary = {}  # key = grid_index (Vector3i), value = WorldChunk instance
var last_player_chunk: Vector3i = Vector3i(999999, 999999, 999999) # force initial update

# Keep track of loading chunks to avoid duplicates
var loading_chunks: Dictionary = {}  # key = chunk_pos, value = true

# Sequential spawn queue
var spawn_queue: Array = []
var is_spawning: bool = false

func _ready():
	player = get_node(player_path)

	# Register any pre-placed chunks
	for child in get_tree().get_nodes_in_group("world_chunk"):
		if child is Node3D and child.has_method("grid_index"):
			var index: Vector3i = child.grid_index
			chunks[index] = child
			print("Registered pre-placed chunk at:", index)

	# Initial chunk population
	_update_loaded_chunks()

func _process(_delta: float) -> void:
	if not player:
		return
	_update_loaded_chunks()

# ------------------------
# Chunk Management with Hysteresis
# ------------------------
func _update_loaded_chunks():
	var player_chunk = world_to_chunk(player.global_transform.origin)

	# Only print when the player moves to a new chunk
	if player_chunk != last_player_chunk:
		print("Player is now in chunk:", player_chunk)
		last_player_chunk = player_chunk

	# ------------------------
	# Enqueue chunks to spawn
	# ------------------------
	var chunk_positions_to_spawn: Array = []
	for x in range(player_chunk.x - view_distance, player_chunk.x + view_distance + 1):
		for y in range(player_chunk.y - view_distance, player_chunk.y + view_distance + 1):
			for z in range(player_chunk.z - view_distance, player_chunk.z + view_distance + 1):
				var pos = Vector3i(x, y, z)
				if not chunks.has(pos) and not loading_chunks.has(pos):
					chunk_positions_to_spawn.append(pos)
					loading_chunks[pos] = true

	# Sort chunks by distance to player (closest first)
	chunk_positions_to_spawn.sort_custom(func(a, b):
		return a.distance_squared_to(player_chunk) > b.distance_squared_to(player_chunk)
	)

	spawn_queue += chunk_positions_to_spawn
	_process_spawn_queue()

	# ------------------------
	# Remove chunks outside hysteresis
	# ------------------------
	var removals = 0
	for chunk_pos in chunks.keys():
		if chunk_pos.distance_to(player_chunk) > view_distance + remove_margin:
			_remove_chunk(chunk_pos)
			removals += 1
			if removals >= max_removals_per_frame:
				break

# ------------------------
# Sequential Async Chunk Spawning
# ------------------------
func _process_spawn_queue():
	if is_spawning or spawn_queue.is_empty():
		return
	is_spawning = true
	var next_pos = spawn_queue.pop_front()
	_spawn_chunk_async(next_pos)

func _spawn_chunk_async(chunk_pos: Vector3i) -> void:
	var t = get_tree().create_timer(0.05)
	t.timeout.connect(func() -> void:
		_spawn_chunk(chunk_pos)
		is_spawning = false
		_process_spawn_queue()
	)

func _spawn_chunk(chunk_pos: Vector3i) -> void:
	if chunks.has(chunk_pos):
		loading_chunks.erase(chunk_pos)
		return

	# Spawn visible test cube
	var chunk = MeshInstance3D.new()
	var cube_mesh = BoxMesh.new()
	cube_mesh.size = chunk_size
	chunk.mesh = cube_mesh
	add_child(chunk)
	chunk.global_position = chunk_to_world(chunk_pos) + chunk_size * 0.5  # center
	chunks[chunk_pos] = chunk
	print("Spawned TEST chunk at:", chunk_pos)

	loading_chunks.erase(chunk_pos)

# ------------------------
# Remove Chunks
# ------------------------
func _remove_chunk(chunk_pos: Vector3i):
	if not chunks.has(chunk_pos):
		return

	var chunk = chunks[chunk_pos]
	if is_instance_valid(chunk):
		chunk.queue_free()
		print("✅ Removed TEST chunk at:", chunk_pos)
	else:
		print("⚠️ Tried to remove chunk at", chunk_pos, "but instance was invalid")

	chunks.erase(chunk_pos)

# ------------------------
# Helpers
# ------------------------
func world_to_chunk(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floori(world_pos.x / chunk_size.x),
		floori(world_pos.y / chunk_size.y),
		floori(world_pos.z / chunk_size.z)
	)

func chunk_to_world(chunk_pos: Vector3i) -> Vector3:
	return Vector3(
		chunk_pos.x * chunk_size.x,
		chunk_pos.y * chunk_size.y,
		chunk_pos.z * chunk_size.z
	)
