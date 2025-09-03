# File: WorldManager.gd
extends Node3D

@export var player_path: NodePath
@export var chunk_size: Vector3 = Vector3(20, 20, 20)

# How far to keep chunks loaded (in chunk cells)
@export var view_distance: int = 1
# Extra hysteresis so we unload only after moving well past view_distance
@export var remove_margin: int = 2

# Streaming safety & smoothness
@export var spawn_interval_sec: float = 0.02   # you found 0.02s feels good
@export var max_removals_per_frame: int = 5    # cap frees per frame

var player: Node3D

# All editor placeholders discovered at startup: Vector3i -> ChunkPlaceholder
var placeholders: Dictionary = {}

# Currently spawned/live chunks: Vector3i -> Node3D (root of instantiated scene)
var chunks: Dictionary = {}

# Spawn queue control
var loading_chunks: Dictionary = {}     # Vector3i -> true (avoid duplicate spawns)
var spawn_queue: Array = []             # Array<Vector3i>
var is_spawning: bool = false

# Track player's chunk to reduce work
var last_player_chunk: Vector3i = Vector3i(999999, 999999, 999999)

func _ready() -> void:
	player = get_node_or_null(player_path)
	_scan_placeholders()
	_update_loaded_chunks()

func _process(_delta: float) -> void:
	if not player:
		return
	_update_loaded_chunks()

# ---------------------------------------------------------
# Discover editor-placed chunk placeholders
# ---------------------------------------------------------
func _scan_placeholders() -> void:
	placeholders.clear()

	for n in get_tree().get_nodes_in_group("world_chunk_placeholder"):
		if n is Node3D:
			var grid := world_to_chunk(n.global_transform.origin)
			if placeholders.has(grid):
				push_warning(
					"Duplicate placeholder at %s. Keeping the first one; ignoring %s." % [str(grid), n.name]
				)
				continue
			placeholders[grid] = n
			print("Registered placeholder", n.name, "at", grid)

# ---------------------------------------------------------
# Main streaming logic (with hysteresis)
# ---------------------------------------------------------
func _update_loaded_chunks() -> void:
	var player_chunk := world_to_chunk(player.global_transform.origin)

	if player_chunk != last_player_chunk:
		print("Player is now in chunk:", player_chunk)
		last_player_chunk = player_chunk

	# Enqueue chunks to spawn within view_distance if a placeholder exists there
	var to_spawn: Array = []
	for x in range(player_chunk.x - view_distance, player_chunk.x + view_distance + 1):
		for y in range(player_chunk.y - view_distance, player_chunk.y + view_distance + 1):
			for z in range(player_chunk.z - view_distance, player_chunk.z + view_distance + 1):
				var pos := Vector3i(x, y, z)
				if not placeholders.has(pos):
					continue # no procedural fill — spawn only where you placed a placeholder
				if not chunks.has(pos) and not loading_chunks.has(pos):
					to_spawn.append(pos)
					loading_chunks[pos] = true

	# Spawn closest first (reduces chance the player sees a late pop)
	to_spawn.sort_custom(func(a, b):
		return a.distance_squared_to(player_chunk) > b.distance_squared_to(player_chunk)
	)
	if to_spawn.size() > 0:
		spawn_queue += to_spawn
		_process_spawn_queue()

	# Remove far chunks with hysteresis (don’t churn)
	var removals := 0
	for pos in chunks.keys().duplicate(): # duplicate to be safe while mutating
		if pos.distance_to(player_chunk) > (view_distance + remove_margin):
			_remove_chunk(pos)
			removals += 1
			if removals >= max_removals_per_frame:
				break

# ---------------------------------------------------------
# Async/throttled spawning
# ---------------------------------------------------------
func _process_spawn_queue() -> void:
	if is_spawning or spawn_queue.is_empty():
		return
	is_spawning = true
	var next_pos: Vector3i = spawn_queue.pop_front()
	_spawn_chunk_async(next_pos)

func _spawn_chunk_async(chunk_pos: Vector3i) -> void:
	var t := get_tree().create_timer(spawn_interval_sec)
	t.timeout.connect(func() -> void:
		_spawn_chunk(chunk_pos)
		is_spawning = false
		_process_spawn_queue()
	)

func _spawn_chunk(chunk_pos: Vector3i) -> void:
	# Might have been spawned meanwhile
	if chunks.has(chunk_pos):
		loading_chunks.erase(chunk_pos)
		return

	var placeholder: Node3D = placeholders.get(chunk_pos, null)
	if placeholder == null:
		# No placeholder — nothing to spawn
		loading_chunks.erase(chunk_pos)
		return

	var inst: Node3D

	# Preferred: instantiate the real scene from the placeholder
	if "chunk_scene" in placeholder and placeholder.chunk_scene:
		inst = placeholder.chunk_scene.instantiate() as Node3D
	else:
		# Fallback: dev/test cube
		var mesh := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = chunk_size
		mesh.mesh = cube
		inst = mesh
		print("Placeholder", placeholder.name, "has no chunk_scene. Spawning TEST cube.")

	# Place it EXACTLY where you positioned the placeholder (snap/stack 1:1)
	inst.global_transform = placeholder.global_transform

	# Name and bookkeeping
	inst.name = "%s__Live@%s" % [placeholder.name, str(chunk_pos)]
	add_child(inst)
	chunks[chunk_pos] = inst

	print("Spawned chunk at:", chunk_pos, "from placeholder:", placeholder.name)
	loading_chunks.erase(chunk_pos)

# ---------------------------------------------------------
# Removal
# ---------------------------------------------------------
func _remove_chunk(chunk_pos: Vector3i) -> void:
	var n: Node3D = chunks.get(chunk_pos, null)
	if n == null:
		return
	if is_instance_valid(n):
		n.queue_free()
		print("Removed chunk at:", chunk_pos)
	else:
		print("Tried to remove chunk at", chunk_pos, "but instance was invalid")
	chunks.erase(chunk_pos)

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
func world_to_chunk(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floori(world_pos.x / chunk_size.x),
		floori(world_pos.y / chunk_size.y),
		floori(world_pos.z / chunk_size.z)
	)
