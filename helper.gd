extends Node

var PhotoPath = "user://photos"
var PhotosTaken = 0
var LastPhotoMetadata: Dictionary = {}

func _ready():
	GetPhotos()

func GetPhotos():
	var dir = DirAccess.open(PhotoPath)
	if dir:
		# skip_navigational = true, skip_hidden = true
		dir.list_dir_begin()

		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				PhotosTaken += 1
			file_name = dir.get_next()

		dir.list_dir_end()
