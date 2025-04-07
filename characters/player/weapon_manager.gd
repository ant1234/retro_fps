extends Node3D

@onready var weapons = $Weapons.get_children()
var weapons_unlocked = []
var cur_slot = 0 
var cur_weapon = null
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var near_by_monster_alert_area_small: Area3D = $NearByMonsterAlertAreaSmall
@onready var near_by_monster_alert_area_large: Area3D = $NearByMonsterAlertAreaLarge
@onready var los_ray_cast_3d: RayCast3D = $LOSRayCast3D

func _ready() -> void:
	for weapon in weapons:
		if !weapon.silent_weapon:
			weapon.fired.connect(alert_enemies_on_fired)
		if weapon.has_method("set_bodies_to_exclude"):
			weapon.set_bodies_to_exclude([get_parent().get_parent()])
	disable_all_weapon()
	for _i in range(weapons.size()):
		weapons_unlocked.append(true)
	switch_to_weapon_slot(0)
		
func attack(input_just_pressed: bool, input_held: bool):
	if  cur_weapon is Weapon:
		cur_weapon.attack(input_just_pressed, input_held)

func disable_all_weapon():
	for weapon in weapons:
		if weapon.has_method("set_active"):
			weapon.set_active(false)
		else:
			weapon.hide()
	
func switch_to_previous_weapon():
	for i in range(weapons.size()):
		var wrapped_ind = wrapi(cur_slot - 1 - i, 0, weapons.size())
		if switch_to_weapon_slot(wrapped_ind):
			break
	
func switch_to_next_weapon():
	for i in range(weapons.size()):
		var wrapped_ind = wrapi(cur_slot + 1 + i, 0, weapons.size())
		if switch_to_weapon_slot(wrapped_ind):
			break
	
func switch_to_weapon_slot(slot_ind: int) -> bool:
	if slot_ind >= weapons.size() or slot_ind < 0:
		return false
	if weapons_unlocked.size() == 0 or !weapons_unlocked[slot_ind]:
		return false
	disable_all_weapon()
	cur_slot = slot_ind
	cur_weapon = weapons[cur_slot]
	if cur_weapon.has_method("set_active"):
		cur_weapon.set_active(true)
	else:
		cur_weapon.show()
	return true
	
func update_animation(velocity: Vector3, grounded: bool):
	if cur_weapon is Weapon and !cur_weapon.is_idle():
		animation_player.play("RESET")
	elif !grounded or velocity.length() < 0.5:
		animation_player.play("RESET", 0.3)
	else:
		animation_player.play("moving", 0.3)
		
func alert_enemies_on_fired():
	for monster in near_by_monster_alert_area_small.get_overlapping_bodies():
		if monster is Monster:
			monster.alert()
	
	for monster in near_by_monster_alert_area_large.get_overlapping_bodies():
		if monster is Monster:
			los_ray_cast_3d.enabled = true
			los_ray_cast_3d.target_position = los_ray_cast_3d.to_local(monster.vision_manager.global_position)
			los_ray_cast_3d.force_raycast_update()
			if !los_ray_cast_3d.is_colliding():
				monster.alert()
			los_ray_cast_3d.enabled = false
	
