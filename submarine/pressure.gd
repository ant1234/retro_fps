extends Control

@export var max_depth: float = 2000.0 # the depth at which pressure bar is full
@export var submarine_path: NodePath
@export var groan_sounds: Array[AudioStream] = [] # assign multiple groan sounds in inspector
@export var min_implode_time: float = 2.0
@export var max_implode_time: float = 8.0
@export var implosion_target: NodePath # node that will handle implosion (e.g. submarine_player)

@onready var pressure_display: ProgressBar = $PressureDisplay
@onready var submarine: Node3D = get_node(submarine_path)
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var implosion_node: Node = get_node_or_null(implosion_target)

var is_doomed: bool = false
var implode_timer: float = 0.0
var has_imploded: bool = false

func _ready():
	add_child(audio_player)
	pressure_display.min_value = 0
	pressure_display.max_value = 100
	pressure_display.value = 0

func _process(delta: float):
	if not submarine:
		return	
	
	# Depth = positive value when submarine descends
	var depth = max(0.0, -submarine.global_transform.origin.y)
	var pressure_percent = clamp(depth / max_depth * 100.0, 0.0, 100.0)
	pressure_display.value = pressure_percent
	
	if pressure_percent >= 100.0:
		if not is_doomed:
			start_implosion_timer()
		else:
			update_implosion_timer(delta)
	else:
		reset_implosion_state()

func start_implosion_timer():
	is_doomed = true
	implode_timer = randf_range(min_implode_time, max_implode_time)
	play_random_groan()

func update_implosion_timer(delta: float):
	implode_timer -= delta
	if implode_timer <= 0.0:
		implode()

func reset_implosion_state():
	is_doomed = false
	implode_timer = 0.0
	if audio_player.playing:
		audio_player.stop()

func play_random_groan():
	if groan_sounds.size() > 0:
		audio_player.stream = groan_sounds.pick_random()
		audio_player.play()

func implode():
	if has_imploded:
		return
	has_imploded = true
	
	print("💥 Submarine imploded!")

	if implosion_node:
		if implosion_node is AudioStreamPlayer:
			if implosion_node.playing:
				implosion_node.stop()
			implosion_node.play()
		elif implosion_node.has_method("on_implode"):
			implosion_node.call("on_implode")
		else:
			print("Implosion target has no handler or sound.")
	else:
		print("No implosion target assigned.")
