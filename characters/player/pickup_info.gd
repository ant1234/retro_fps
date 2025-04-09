extends Label

var lines = []
const MAX_LINES = 5
const DELETE_LINE_AFTER_TIME = 3.0

var delete_timer : Timer

func _ready():
	delete_timer = Timer.new()
	add_child(delete_timer)
	delete_timer.wait_time = DELETE_LINE_AFTER_TIME
	delete_timer.timeout.connect(delete_line)
	update_display()
	
func on_pickup(pickup: Pickup):
	if pickup.pickup_type == Pickup.PICKUP_TYPS.HEALTH:
		add_line("Picked Up %s Health" % pickup.pickup_amnt)
		return
		
	var weapon_name = Pickup.WEAPONS.keys()[pickup.weapon_type].capitalize()
	if pickup.pickup_type == Pickup.PICKUP_TYPS.WEAPON:
		add_line("Picked Up %s" % weapon_name)
	if pickup.pickup_type == Pickup.PICKUP_TYPS.AMMO:
		add_line("Picked Up %s %s Ammo" % [pickup.pickup_amnt, weapon_name])		
		
func add_line(line_text: String):
	delete_timer.start()
	lines.push_back(line_text)
	if lines.size() > MAX_LINES:
		lines.pop_front()
	update_display()
	
func delete_line():
	lines.pop_front()
	update_display()

func update_display():
	var s = ""
	for line in lines:
		s += line + "\n"
	text = s
