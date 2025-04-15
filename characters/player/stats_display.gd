extends Control
@onready var health_manager: Node3D = %HealthManager
@onready var weapon_manager: Node3D = %WeaponManager
@onready var ammo_display: Label = $AmmoDisplay
@onready var health_display: ProgressBar = $HealthDisplay


func _ready():
	health_manager.health_changed.connect(update_health_display)
	for weapon in weapon_manager.weapons:
		weapon.ammo_updated.connect(update_ammo_display)
	update_health_display(health_manager.cur_health, health_manager.max_health)
	if weapon_manager.cur_weapon:
		update_ammo_display(weapon_manager.cur_weapon.ammo)
	
func update_health_display(cur_health: int, max_health: int):
	health_display.max_value = max_health
	health_display.value = cur_health
	
func update_ammo_display(ammo_amnt: int):
	if ammo_amnt < 0:
		ammo_display.text = "Ammo: inf"
	else:
		ammo_display.text = "Ammo: %s" % ammo_amnt
