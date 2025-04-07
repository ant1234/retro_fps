extends CharacterMover

@export var turn_speed = 300.0
var facing_dir : Vector3
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
var moving = false

func _ready() -> void:
	super()
	facing_dir = -character_body.global_transform.basis.z
	
func move_to_point(point: Vector3):
	moving = true
	navigation_agent_3d.target_position = point
	
func stop_moving():
	moving = false
	set_move_dir(Vector3.ZERO)
	
func set_facing_dir(new_face_dir: Vector3):
	facing_dir = new_face_dir
	facing_dir.y = 0.0

func _physics_process(delta: float) -> void:
	super(delta)
	## MOVEMENT
	if moving:
		set_move_dir(navigation_agent_3d.get_next_path_position() - global_position)
		
	
	## FACING
	var fwd = character_body.global_transform.basis.z
	var right = character_body.global_transform.basis.x
	var angle_diff = fwd.angle_to(facing_dir)
	var turn_dir = 1
	
	if right.dot(facing_dir) > 0:
		turn_dir = -1
		
	var turn_amnt = delta * deg_to_rad(turn_speed)
	if turn_amnt > angle_diff:
		turn_amnt = angle_diff
		
	character_body.global_rotation.y += turn_amnt * turn_dir
	
