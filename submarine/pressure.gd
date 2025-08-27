extends Control

# ------------------------
# Pressure / Implosion Settings
# ------------------------
@export var max_depth: float = 2000.0 # depth at which pressure bar is full
@export var submarine_path: NodePath
@export var groan_sounds: Array[AudioStream] = [] # metallic groaning sounds
@export var min_implode_time: float = 2.0
@export var max_implode_time: float = 8.0
@export var implosion_target: NodePath # node that will handle implosion (submarine or AudioStreamPlayer)
@export var min_angle: float = -120.0 # needle at 0% pressure
@export var max_angle: float = 120.0  # needle at 100% pressure

# ------------------------
# Gauge Colors (exported for Inspector)
# ------------------------
@export var dial_color: Color = Color.DIM_GRAY
@export var tick_color: Color = Color.WHITE
@export var danger_color: Color = Color.RED
@export var needle_color: Color = Color.YELLOW
@export var center_color: Color = Color.BLACK
@export var border_color: Color = Color.WHITE # border color
@export var border_thickness: float = 4.0   # border thickness

# ------------------------
# Internal Nodes
# ------------------------
@onready var submarine: Node3D = get_node(submarine_path)
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var implosion_node: Node = get_node_or_null(implosion_target)

# ------------------------
# Internal State
# ------------------------
var is_doomed: bool = false
var implode_timer: float = 0.0
var has_imploded: bool = false
var pressure_percent: float = 0.0

# ------------------------
# Ready
# ------------------------
func _ready():
	add_child(audio_player)

# ------------------------
# Process - update pressure & implosion timer
# ------------------------
func _process(delta: float):
	if not submarine:
		return
	
	# Depth = positive value when submarine descends
	var depth = max(0.0, -submarine.global_transform.origin.y)
	pressure_percent = clamp(depth / max_depth, 0.0, 1.0)

	# Check for full pressure
	if pressure_percent >= 1.0:
		if not is_doomed:
			start_implosion_timer()
		else:
			update_implosion_timer(delta)
	else:
		reset_implosion_state()

	queue_redraw() # redraw gauge each frame

# ------------------------
# Implosion Logic
# ------------------------
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
	
	print("Submarine imploded!")

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

# ------------------------
# Draw the procedural submarine-style gauge
# ------------------------
func _draw():
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 10

	# Border (draw a slightly larger ring)
	draw_arc(center, radius, 0, 2*PI, 64, border_color, border_thickness)

	# Outer circle (dial fill)
	draw_circle(center, radius - border_thickness/2, dial_color)

	# Tick marks
	for i in range(0, 11):
		var t = float(i) / 10.0
		var angle = deg_to_rad(lerp(min_angle, max_angle, t))
		var inner = center + Vector2(cos(angle), sin(angle)) * (radius - 10)
		var outer = center + Vector2(cos(angle), sin(angle)) * radius
		draw_line(inner, outer, tick_color, 2)

	# Red danger arc (last 20%)
	var danger_start = deg_to_rad(lerp(min_angle, max_angle, 0.8))
	var danger_end = deg_to_rad(max_angle)
	draw_arc(center, radius - 5, danger_start, danger_end - danger_start, 30, danger_color, 3)

	# Needle
	var needle_angle = deg_to_rad(lerp(min_angle, max_angle, pressure_percent))
	var needle_end = center + Vector2(cos(needle_angle), sin(needle_angle)) * (radius - 20)
	draw_line(center, needle_end, needle_color, 4)

	# Center cap
	draw_circle(center, 6, center_color)
