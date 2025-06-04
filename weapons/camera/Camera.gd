extends Control

# "Camera CANON EOS 400D" (https://skfb.ly/6VsDZ) by santy is licensed under Creative Commons Attribution 
# (http://creativecommons.org/licenses/by/4.0/).

var FileName = "photo"
@onready var Hlpr: Node = $"../../../Helper"

func _ready():
	CreatePhotoDir()

func SavePhoto():
	var image: Image = get_viewport().get_texture().get_image()
	var photo_index = Hlpr.PhotosTaken
	var photo_base_path = "user://photos/photo" + str(photo_index)

	# Save the image
	var err = image.save_png(photo_base_path + ".png")
	if err != OK:
		print("❌ Failed to save photo image:", err)
		return

	# Save metadata as JSON if a subject was captured
	var subject_info = Hlpr.LastPhotoMetadata
	if subject_info:
		var json_string = JSON.stringify(subject_info, "\t")
		var file = FileAccess.open(photo_base_path + ".json", FileAccess.WRITE)
		file.store_string(json_string)
		file.close()
	else:
		print("ℹ️ No metadata available for this photo.")

	Hlpr.PhotosTaken += 1

func CreatePhotoDir():
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("user://photos"):
			dir.make_dir("user://photos")

func ChangeExposure(ex: float):
	var ExposureValue = $VBoxContainer/HBoxContainer/Exposure2
	ExposureValue.text = str(ex)
