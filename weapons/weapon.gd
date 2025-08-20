extends Node3D
class_name Weapon 

@onready var animation_player: AnimationPlayer = $Graphics/AnimationPlayer
@onready var bullet_emitter: BulletEmitter = $BulletEmitter
@onready var fire_point: Node3D = %FirePoint

@export var automatic = false
var did_capture := false
var _taking_photo := false

@export var damage = 5
@export var ammo = 0

@export var attack_rate = 0.2
var last_attack_time = -9999.9
var CameraInUse = false
var has_shown_out_of_ammo_message: bool = false
var hide_for_screenshot := false

@export var animation_controller_attack = false
@export var silent_weapon = false

signal fired
signal out_of_ammo
signal ammo_updated(add_ammo: int)


func _ready() -> void:
	bullet_emitter.set_damage(damage)

	DialogueManager.game_states.clear()
	DialogueManager.game_states.append(self) 
	DialogueManager.game_states.append(GameState)
	DialogueManager.dialogue_ended.connect(to_camera_check)

func _input(event):
	# Handle camera toggle with right mouse button
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				CameraInUse = true
			else:
				CameraInUse = false

	# Left mouse attack
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and CameraInUse:
			TakePhoto()

func _process(delta):
	# Keep reticle in sync every frame
	show_reticle(CameraInUse and not hide_for_screenshot)


func show_reticle(state: bool):
	var crosshairs = get_node_or_null("Crosshairs")
	if crosshairs:
		crosshairs.visible = state


func play_animation_safe(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func play_animation_backwards_safe(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play_backwards(anim_name)

func TakePhoto():
	# Flash animation
	var AnPl = $"../DigitalCamera/Graphics/ViewFinder/CameraEOS/CameraViewport/CameraOverlay/AnimationPlayer"
	if AnPl:
		AnPl.play("flash")

func set_bodies_to_exclude(bodies: Array):
	bullet_emitter.set_bodies_to_exclude(bodies)

func attack(input_just_pressed: bool, input_held: bool):
	if not automatic and not input_just_pressed:
		return

	if automatic and not input_held:
		return

	if ammo == 0:
		if input_just_pressed:
			out_of_ammo.emit()
			if has_node("OutOfAmmo"):
				$OutOfAmmo.play()
				
			if not has_shown_out_of_ammo_message:
				var dialogue_res = load("res://dialogue/out_of_ammo.dialogue")
				if dialogue_res and CustomDialogueManager:
					CustomDialogueManager.show_dialogue_balloon(dialogue_res, "start")
					has_shown_out_of_ammo_message = true
		return

	has_shown_out_of_ammo_message = false

	var cur_time = Time.get_ticks_msec() / 1000.0
	if cur_time - last_attack_time < attack_rate:
		return

	if ammo > 0:
		ammo -= 1

	if not animation_controller_attack:
		actually_attack()

	last_attack_time = cur_time
	play_animation_safe("attack")
	fired.emit()
	$AttackSounds.play()
	ammo_updated.emit(ammo)
	if has_node("Graphics/MuzzleFlash"):
		$Graphics/MuzzleFlash.flash()


func actually_attack():
	bullet_emitter.global_transform = fire_point.global_transform
	bullet_emitter.fire()

func set_active(a: bool):
	var crosshairs = get_node_or_null("Crosshairs")
	if crosshairs:
		crosshairs.visible = a

	visible = a

	if not a:
		play_animation_safe("RESET")
	else:
		$EquipSound.play()
		ammo_updated.emit(ammo)
		
func is_idle() -> bool:
	return not animation_player.is_playing()

func add_ammo(amnt: int):
	ammo += amnt
	ammo_updated.emit(ammo)         
	
func to_camera_check(resource = null):
	SceneRouter.goto_scene("res://scenes/camera_check_page.tscn")
