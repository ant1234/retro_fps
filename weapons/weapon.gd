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

@export var animation_controller_attack = false
@export var silent_weapon = false

signal fired
signal out_of_ammo
signal ammo_updated(add_ammo: int)

func _ready() -> void:
	bullet_emitter.set_damage(damage)
	
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
