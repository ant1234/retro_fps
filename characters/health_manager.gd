extends Node3D

@export var max_health = 100
@onready var cur_health = max_health
@export var gib_at = -10
@export var verbose = true

signal died
signal healed
signal damaged
signal gibbed 
signal health_changed(cur_health, max_health)

func _ready():
	health_changed.emit(cur_health, max_health)
	if verbose:
		print("Starting health: %s/%s" % [cur_health, max_health])
		
func hurt(damage_data: DamageData):
	if cur_health <= 0:
		return
	cur_health -= damage_data.amount
	if cur_health <= gib_at:
		gibbed.emit()
	if cur_health <= 0:
		died.emit()
	else:
		damaged.emit()
	health_changed.emit(cur_health, max_health)
	if verbose:
		print("Damaged for %s, health: %s/%s" % [damage_data.amount, cur_health, max_health])
		
func heal(amount: int):
	if cur_health <= 0:
		return
	cur_health = clamp(cur_health + amount, 0, max_health)
	healed.emit()
	health_changed.emit(cur_health, max_health)
	if verbose:
		print("Healed for %s, health: %s/%s" % [amount, cur_health, max_health])
		
func test_damage():
	var d = DamageData.new()
	d.amount = 30
	hurt(d)
		
		
