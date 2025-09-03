# File: ChunkPlaceholder.gd
@tool
extends Node3D

## Assign the actual chunk scene to spawn here (e.g., OpenOcean.tscn, Wreck.tscn, Cave.tscn).
@export var chunk_scene: PackedScene

## Keep this identical to WorldManager.chunk_size so snapping & grid index match.
@export var chunk_size: Vector3 = Vector3(20, 20, 20)

## Editor convenience
@export var snap_to_grid: bool = true
@export var show_grid_index_in_name: bool = true

## Computed from global position using chunk_size
var grid_index: Vector3i:
	get:
		return Vector3i(
			floori(global_position.x / chunk_size.x),
			floori(global_position.y / chunk_size.y),
			floori(global_position.z / chunk_size.z)
		)

func _enter_tree() -> void:
	# Make sure the manager can find us
	add_to_group("world_chunk_placeholder", true)

func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_editor_helpers()

func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_apply_editor_helpers()

func _apply_editor_helpers() -> void:
	if snap_to_grid:
		var snapped := Vector3(
			snappedf(global_position.x, chunk_size.x),
			snappedf(global_position.y, chunk_size.y),
			snappedf(global_position.z, chunk_size.z)
		)
		if snapped != global_position:
			global_position = snapped
	if show_grid_index_in_name:
		var gi := grid_index
		# Keep your manual name prefix; append the grid for clarity.
		var base := name.split("@")[0]
		name = "%s@%s" % [base, str(gi)]
