extends Node3D

class_name Weapon 

@onready var animation_player: AnimationPlayer = $Graphics/AnimationPlayer
@onready var bullet_emitter: BulletEmitter = $BulletEmitter
@onready var fire_point: Node3D = %FirePoint

@export var automatic = false

@export var damage = 5
@export var ammo = 0

@export var attack_rate = 0.2
var last_attack_time = -9999.9
var CameraInUse = false

@export var animation_controller_attack = false
@export var silent_weapon = false

signal fired
signal out_of_ammo
signal ammo_updated(add_ammo: int)

func _ready() -> void:
	bullet_emitter.set_damage(damage)
	
# camera functionality
func _input(event):

	if Input.is_action_just_pressed("raise_camera"):
		animation_player.play("raise_camera")
		CameraInUse = true
		
	if Input.is_action_just_released("raise_camera"):
		animation_player.play_backwards("raise_camera")
		CameraInUse = false
		
	if Input.is_action_just_pressed("attack") && CameraInUse:
		TakePhoto()
	
func TakePhoto():
	var AnPl = $"../DigitalCamera/Graphics/ViewFinder/CameraEOS/CameraViewport/CameraOverlay/AnimationPlayer"
	if AnPl: AnPl.play("flash")
	
	await get_tree().process_frame  # Wait 1 frame to ensure viewport is ready
	
	var viewport_camera: Camera3D = $"../DigitalCamera/Graphics/ViewFinder/CameraEOS/CameraViewport/ViewportCamera"
	if not is_instance_valid(viewport_camera):
		print("❌ Viewport camera not valid")
		return
	
	var camera_vp = viewport_camera.get_viewport()
	var screen_size = camera_vp.get_visible_rect().size
	
	var from = viewport_camera.project_ray_origin(screen_size / 2)
	var to = from + viewport_camera.project_ray_normal(screen_size / 2) * 100.0
	
	# ✅ Create raycast parameters
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.get("collider")
		if collider:
			var subject_node = collider.get_node_or_null("PhotoSubject")
			if subject_node:
				print("📸 Subject captured!")
				print("  Name: ", subject_node.subject_name)
				print("  Desc: ", subject_node.description)
				print("  Rareness: ", subject_node.rareness)
			else:
				print("❌ Hit something, but it's not a subject: ", collider.name)
	else:
		print("🌌 Nothing in camera view.")
	
	var overlay_script: Node = $"../DigitalCamera/Graphics/ViewFinder/CameraEOS/CameraViewport/CameraOverlay"
	if overlay_script.has_method("SavePhoto"):
		overlay_script.SavePhoto()

	
func set_bodies_to_exclude(bodies: Array):
	bullet_emitter.set_bodies_to_exclude(bodies)
	
func attack(input_just_pressed: bool, input_held: bool):
	if !automatic and !input_just_pressed:
		return
		
	if automatic and !input_held:
		return
		
	if ammo == 0:
		if input_just_pressed:
			out_of_ammo.emit()
			if has_node("OutOfAmmo"):
				$OutOfAmmo.play()
		return
		
	var cur_time = Time.get_ticks_msec() / 1000.0
	if cur_time - last_attack_time < attack_rate:
		return
	
	if ammo > 0:
		ammo -= 1 
		
	if !animation_controller_attack:
		actually_attack()
		
	last_attack_time = cur_time
	animation_player.stop()
	animation_player.play("attack")
	fired.emit()
	$AttackSounds.play()
	ammo_updated.emit(ammo)
	if has_node("Graphics/MuzzleFlash"):
		$Graphics/MuzzleFlash.flash()
	
func actually_attack():
	bullet_emitter.global_transform = fire_point.global_transform
	bullet_emitter.fire()
		
func set_active(a: bool):
	if $Crosshairs:
		$Crosshairs.visible = a
		visible = a
	if !a:
		animation_player.play("RESET")
	else:
		$EquipSound.play()
		ammo_updated.emit(ammo)
		
func is_idle() -> bool:
	return !animation_player.is_playing()
	
func add_ammo(amnt: int):
	ammo += amnt
	ammo_updated.emit(ammo)
	
	
