@tool
extends Node3D
class_name SuperChunk

@export var chunk_size: Vector3 = Vector3(20, 20, 20)
@export var auto_chunk: bool = true
@export var clear_old_chunks: bool = true
@export var baked: bool = false  # baked flag

## Drag your WorldChunk.tscn here in the editor
@export var world_chunk_scene: PackedScene

@export var chunk_content_scene: PackedScene

func _ready():
	if Engine.is_editor_hint() and auto_chunk and not baked:
		_process_into_chunks()

func _process_into_chunks():
	if world_chunk_scene == null:
		push_warning("SuperChunk: No WorldChunk scene assigned!")
		return

	# Ensure we have a World parent
	var world_node: Node3D = get_parent()
	if world_node == null:
		push_warning("SuperChunk must be a child of World node")
		return

	# Find or create the WorldChunks container
	var container: Node3D = world_node.get_node_or_null("WorldChunks")
	if container == null:
		container = Node3D.new()
		container.name = "WorldChunks"
		world_node.add_child(container)

	# Optional: clear existing chunks before baking
	if clear_old_chunks:
		for c in container.get_children():
			if c is WorldChunk:
				container.remove_child(c)
				c.queue_free()

	# Calculate superchunk bounds
	var aabb := _calculate_bounds()

	# Spawn chunks inside WorldChunks
	for x in range(floori(aabb.position.x / chunk_size.x), ceili((aabb.position.x + aabb.size.x) / chunk_size.x)):
		for y in range(floori(aabb.position.y / chunk_size.y), ceili((aabb.position.y + aabb.size.y) / chunk_size.y)):
			for z in range(floori(aabb.position.z / chunk_size.z), ceili((aabb.position.z + aabb.size.z) / chunk_size.z)):
				var chunk: WorldChunk = world_chunk_scene.instantiate()
				chunk.name = "WorldChunk_(%d,%d,%d)_(%d,%d,%d)" % [x,y,z, x,y,z]
				chunk.grid_index = Vector3i(x, y, z)
				chunk.size = chunk_size
				container.add_child(chunk)

				# Assign content that falls into this chunk
				_assign_content_to_chunk(chunk)

	baked = true
	notify_property_list_changed()
	print("SuperChunk baked into WorldChunks container")

func reset_bake():
	# Find the WorldChunks container and remove all WorldChunks inside it
	var world_node: Node3D = get_parent()
	if world_node == null:
		push_warning("SuperChunk must be a child of World node")
		return

	var container: Node3D = world_node.get_node_or_null("WorldChunks")
	if container:
		for c in container.get_children():
			if c is WorldChunk:
				container.remove_child(c)
				c.queue_free()

	baked = false
	notify_property_list_changed()
	print("SuperChunk bake reset. You can bake again.")

func _calculate_bounds() -> AABB:
	var aabb := AABB()
	var first := true
	for c in get_children():
		if c is WorldChunk:
			continue
		if c.has_method("get_aabb"):
			var child_aabb: AABB = c.get_aabb()
			if first:
				aabb = child_aabb
				first = false
			else:
				aabb = aabb.merge(child_aabb)
		else:
			var pos: Vector3 = c.global_position
			var fallback := AABB(pos, Vector3.ONE)
			if first:
				aabb = fallback
				first = false
			else:
				aabb = aabb.merge(fallback)
	return aabb

func _assign_content_to_chunk(chunk: WorldChunk):
	if chunk_content_scene == null:
		push_warning("SuperChunk: No ChunkContent scene assigned!")
		return

	# Instantiate ChunkContent inside this chunk
	var content_instance: Node3D = chunk_content_scene.instantiate()
	chunk.add_child(content_instance)

	# Position content relative to the chunk
	# Assuming the chunk’s global_position is the center
	content_instance.global_position = chunk.global_position
