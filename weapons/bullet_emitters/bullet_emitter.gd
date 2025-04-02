extends Node3D

class_name BulletEmitter

var bodies_to_exclude = []
var damage = 1

func set_damage(d: int):
	damage = d
	for child in get_children():
		if child is BulletEmitter:
			child.set_damage(d)

func set_bodies_to_exclude(bodies: Array):
	bodies_to_exclude = bodies
	for child in get_children():
		if child is BulletEmitter:
			child.set_bodies_to_exclude(bodies)
			
func fire():
	for child in get_children():
		if child is BulletEmitter:
			child.fire()
