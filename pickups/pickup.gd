class_name Pickup extends Area3D

enum PICKUP_TYPS {HEALTH, WEAPON, AMMO}
enum WEAPONS {MACHINE_GUN, SHOTGUN, ROCKET_LAUNCHER}

@export var pickup_type = PICKUP_TYPS.HEALTH
@export var weapon_type = WEAPONS.MACHINE_GUN
@export var pickup_amnt = 20

func pickup():
	queue_free()
