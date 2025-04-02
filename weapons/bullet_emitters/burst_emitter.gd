extends BulletEmitter

@export var burst_count = 500

func fire():
	for _i in range(burst_count):
		super()
