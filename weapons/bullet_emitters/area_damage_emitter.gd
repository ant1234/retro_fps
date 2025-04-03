extends BulletEmitter

@onready var los_raycast: RayCast3D = $LOSRaycast
@export var attack_radius := 1.0

@export var offset_by_radius = false

func fire():
	
	var query_params := PhysicsShapeQueryParameters3D.new()
	query_params.shape = SphereShape3D.new()
	query_params.shape.radius = attack_radius
	query_params.collision_mask = 2
	
	var tr = global_transform
	if offset_by_radius:
		tr.origin = to_global(Vector3.FORWARD * attack_radius)
	query_params.transform = tr 
	query_params.exclude = bodies_to_exclude
	
	var intersect_results : Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(query_params)
	for intersect_data in intersect_results:
		var collider : Node3D = intersect_data.collider
		if collider.has_method("hurt") and has_los(collider):
			var damage_data = DamageData.new()
			damage_data.amount = damage
			damage_data.hit_pos = collider.global_position + Vector3.UP
			collider.hurt(damage_data)
		super()
		
func has_los(collider: Node3D) -> bool:
	los_raycast.enabled = true
	los_raycast.target_position = los_raycast.to_local(collider.global_position + Vector3.UP)
	los_raycast.force_raycast_update()
	
	var in_los = !los_raycast.is_colliding()
	los_raycast.enabled = false
	
	return in_los
			
