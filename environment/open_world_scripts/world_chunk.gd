@tool
extends Node3D
class_name WorldChunk

# The real content for this chunk (reef, cave, wreck, etc.) is assigned dynamically by SuperChunk
@export var chunk_scene: PackedScene

# Metadata you can use later (fish rules, lighting tweaks, etc.)
@export var biome_type: String = "default"

# Size of the chunk cube in world units
@export var size: Vector3 = Vector3(20, 20, 20)

# Optional: grid index so chunks snap perfectly in a 3D grid
@export var grid_index: Vector3i = Vector3i.ZERO

@export var snap_to_grid: bool = true

@onready var _placeholder: MeshInstance3D = get_node("EditorOnly/Placeholder")

func _ready() -> void:
	_apply_size()
	_make_placeholder_material()
	_apply_snap()
	add_to_group("world_chunk")

# Manual setters to use in code instead of setget
func set_size(v: Vector3) -> void:
	size = v
	_apply_size()
	if snap_to_grid:
		_apply_snap()

func set_grid_index(v: Vector3i) -> void:
	grid_index = v
	if snap_to_grid:
		_apply_snap()

func _apply_size() -> void:
	if _placeholder and _placeholder.mesh is BoxMesh:
		var bm := _placeholder.mesh as BoxMesh
		bm.size = size
		_placeholder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _apply_snap() -> void:
	# Position the chunk so its center sits at index * size.
	global_position = Vector3(
		grid_index.x * size.x,
		grid_index.y * size.y,
		grid_index.z * size.z
	)

func _make_placeholder_material() -> void:
	if not _placeholder:
		return
	if _placeholder.material_override == null:
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.2, 0.6, 1.0, 0.15) # bluish, 15% opaque
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.disable_receive_shadows = true
		_placeholder.material_override = m

func _get_configuration_warnings() -> PackedStringArray:
	var w := PackedStringArray()
	if get_node_or_null("EditorOnly/Placeholder") == null:
		w.append("Add EditorOnly → MeshInstance3D named 'Placeholder' with a BoxMesh.")
	return w
