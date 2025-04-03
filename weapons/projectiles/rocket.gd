extends Projectile
@onready var area_damage_emitter: Node3D = $AreaDamageEmitter

func on_hit(hit_collider: Node3D, hit_pos: Vector3, hit_normal: Vector3):
	super(hit_collider, hit_pos, hit_normal)
	$TrailSmokeParticles.emitting = false
	area_damage_emitter.damage = damage
	area_damage_emitter.fire()
	$ExplosionFireBall.restart()
	$ExplosionSparkParticles.restart()
	
	await get_tree().create_timer(0.15).timeout
	$ExplosionSmokeParticles.restart()
