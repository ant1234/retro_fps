extends CharacterBody3D

@onready var camera_3d: Camera3D = $Camera3D
@onready var character_mover: Node3D = $CharacterMover
@onready var health_manager: Node3D = $HealthManager
@onready var weapon_manager: Node3D = $Camera3D/WeaponManager
@export var mouse_sensitivity_h = 0.15
@export var mouse_sensitivity_v = 0.15
@onready var death_screen: Control = $PlayerUILayer/DeathScreen
@onready var proximity_area: Area3D = $Area3D

var dead = false

# --- Camera shift feature ---
var max_shift := 2.0
var camera_original_pos: Vector3
var camera_current_offset := 0.0
var camera_target_offset := 0.0
var camera_step := 0.2          # how much the camera moves per scroll tick
var camera_lerp_speed := 5.0    # higher = faster smoothing

const HOTKEYS = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
	KEY_6: 5,
	KEY_7: 6,
	KEY_8: 7,
	KEY_9: 8,
	KEY_0: 9,
}

func _ready() -> void:
	proximity_area.connect("body_entered", _on_body_entered)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_manager.died.connect(kill)

	camera_original_pos = camera_3d.position


func _on_body_entered(body):
	if body.is_in_group("fish"):
		var parent_node: Node = body.get_parent()
		if parent_node and parent_node.has_method("all_fish"):
			var maybe_arr = parent_node.get("all_fish")
			if typeof(maybe_arr) == TYPE_ARRAY:
				(maybe_arr as Array).erase(body)
		body.call_deferred("queue_free")


func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity_h
		rotation_degrees.x += event.relative.y * mouse_sensitivity_v
		rotation_degrees.x = clamp(rotation_degrees.x, -45, 45)
		
	if event is InputEventMouseButton and event.pressed:
		# --- Weapon scroll ---
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			weapon_manager.switch_to_previous_weapon()
			# Increment target offset forward
			camera_target_offset = clamp(camera_target_offset + camera_step, 0, max_shift)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			weapon_manager.switch_to_next_weapon()
			# Increment target offset backward
			camera_target_offset = clamp(camera_target_offset - camera_step, 0, max_shift)

	if event is InputEventKey and event.pressed and event.keycode in HOTKEYS:
		weapon_manager.switch_to_weapon_slot(HOTKEYS[event.keycode])


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		get_tree().call_group("instanced", "queue_free")
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("fullscreen"):
		var fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if dead:
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var move_dir = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	character_mover.set_move_dir(move_dir)
	
	if Input.is_action_just_pressed("jump"):
		character_mover.jump()
		
	weapon_manager.attack(Input.is_action_just_pressed("attack"), Input.is_action_pressed("attack"))

	# --- Smoothly lerp camera towards target offset ---
	camera_current_offset = lerp(camera_current_offset, camera_target_offset, camera_lerp_speed * delta)
	camera_3d.position = camera_original_pos + Vector3(0, 0, camera_current_offset)


func kill():
	dead = true
	character_mover.set_move_dir(Vector3.ZERO)
	death_screen.show_death_screen()
	
func hurt(damage_data: DamageData):
	health_manager.hurt(damage_data)
