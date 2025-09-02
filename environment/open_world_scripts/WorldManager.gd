# WorldManager.gd
extends Node3D

@export var player_path: NodePath   # drag your Player node here
@export var chunk_size: Vector3 = Vector3(20, 20, 20)

var player: Node3D
var chunks: Dictionary = {}  # key = grid_index (Vector3i), value = WorldChunk

func _ready():
	player = get_node(player_path)

	# Collect all child WorldChunk nodes (placed in editor under a "Chunks" node, for example)
	for child in get_tree().get_nodes_in_group("world_chunk"):
		if child is Node3D:
			var index: Vector3i = child.grid_index
			chunks[index] = child
			print("Registered chunk at: ", index)

func _process(delta):
	if not player:
		return
		
	var pos = player.global_position
	var current_chunk = world_to_chunk(player.global_transform.origin)
	print("Player pos:", pos, " | chunk:", current_chunk)

	# (later: trigger async load/unload here)
	pass


func world_to_chunk(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		int(floor(world_pos.x / chunk_size.x)),
		int(floor(world_pos.y / chunk_size.y)),
		int(floor(world_pos.z / chunk_size.z))
	)
