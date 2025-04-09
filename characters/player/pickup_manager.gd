extends Area3D
@onready var health_manager: Node3D = %HealthManager
@onready var weapon_manager: Node3D = %WeaponManager
@onready var pickup_info: Label = %PickupInfo
@onready var ammo_sounds = {
	Pickup.WEAPONS.MACHINE_GUN: $PickupMGAmmo,
	Pickup.WEAPONS.SHOTGUN: $PickupSGAmmo,
	Pickup.WEAPONS.ROCKET_LAUNCHER: $PickupRLAmmo,
}

func _ready():
	area_entered.connect(on_area_enter)
	
func on_area_enter(pickup: Area3D):
	var delete_on_pickup = true
	if pickup is Pickup:
		match pickup.pickup_type:
			Pickup.PICKUP_TYPS.HEALTH:
				if health_manager.cur_health < health_manager.max_health:
					health_manager.heal(pickup.pickup_amnt)
					$PickupHealth.play()
				else:
					delete_on_pickup = false
			Pickup.PICKUP_TYPS.WEAPON:
				var weapon : Weapon = weapon_manager.get_weapon_from_pickup_type(pickup.weapon_type)
				weapon_manager.weapon_enable(weapon)
				weapon.add_ammo(pickup.pickup_amnt)
				ammo_sounds[pickup.weapon_type].play()

			Pickup.PICKUP_TYPS.AMMO:
				var weapon : Weapon = weapon_manager.get_weapon_from_pickup_type(pickup.weapon_type)
				weapon.add_ammo(pickup.pickup_amnt)
				ammo_sounds[pickup.weapon_type].play()
				
	if delete_on_pickup:
		pickup_info.on_pickup(pickup)
		pickup.pickup()
