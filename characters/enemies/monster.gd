class_name Monster extends CharacterBody3D

@onready var health_manager: Node3D = $HealthManager
@export var animation_player : AnimationPlayer
@onready var vision_manager: VisionManager = $VisionManager
@onready var near_by_monster_alert_area: Area3D = $NearByMonsterAlertArea
@onready var ai_character_mover: Node3D = $AICharacterMover
@onready var player = get_tree().get_first_node_in_group("player")
@onready var attack_emitter: BulletEmitter = $AttackEmitter

@export var attack_range = 2.0
@export var damage = 15

@export var attack_speed_modifier = 1.0

enum STATES {IDLE, ATTACK, DEAD}
var cur_state = STATES.IDLE

func _ready() -> void:
	var hitboxes = find_children("*", "HitBox")
	for hitbox in hitboxes:
		hitbox.on_hurt.connect(health_manager.hurt)
		
	health_manager.died.connect(set_state.bind(STATES.DEAD))
	health_manager.gibbed.connect(queue_free)
	hitboxes.append(self)
	attack_emitter.set_bodies_to_exclude(hitboxes)
	attack_emitter.set_damage(damage)
	set_state(STATES.IDLE)

func hurt(damage_data: DamageData):
	health_manager.hurt(damage_data)
	
func alert():
	if cur_state == STATES.IDLE:
		$AlertSound.play()
		set_state(STATES.ATTACK)
		alert_nearby_monsters()
		
func alert_nearby_monsters():
	for b in near_by_monster_alert_area.get_overlapping_bodies():
		if b is Monster:
			b.alert()
	
func set_state(state: STATES):
	if cur_state == STATES.DEAD:
		return
	cur_state = state
	match cur_state:
		STATES.ATTACK:
			print("attack state set")
		STATES.IDLE:
			animation_player.play("idle")
		STATES.DEAD:
			animation_player.play("die", 0.2)
			collision_layer = 0
			collision_mask = 1
			ai_character_mover.stop_moving()
			
func _process(delta: float) -> void:
	match cur_state:
		STATES.IDLE:
			process_idle_state(delta)
		STATES.ATTACK:
			process_attack_state(delta)
			
func process_idle_state(_delta):
	if vision_manager.can_see_target(player):
		alert()
	
func process_attack_state(_delta):
	var attacking = animation_player.current_animation == "attack"
	var vec_to_player = player.global_position - global_position
	if vec_to_player.length() <= attack_range:
		ai_character_mover.stop_moving()
		if !attacking and vision_manager.is_facing_target(player):
			start_attack()
		elif !attacking:
			ai_character_mover.set_facing_dir(vec_to_player)
	elif !attacking:
				
		ai_character_mover.set_facing_dir(ai_character_mover.move_dir)
		ai_character_mover.move_to_point(player.global_position)
		animation_player.play("walk", -1, 2.0)
	
func start_attack():
	$AttackSound.play()
	animation_player.play("attack", -1, attack_speed_modifier)
		
func do_attack(): # called from animation
	attack_emitter.fire()
		
