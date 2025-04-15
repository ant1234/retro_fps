extends Control

# "Camera CANON EOS 400D" (https://skfb.ly/6VsDZ) by santy is licensed under Creative Commons Attribution 
# (http://creativecommons.org/licenses/by/4.0/).

var FileName = "photo"
@onready var Hlpr = get_node("/root/Helper")

func _ready():
	CreatePhotoDir()

func SavePhoto():
	var image: Image = get_viewport().get_texture().get_image()
	image.flip_y()
	
	var photo_path = "res://photos/" + FileName + str(Hlpr.PhotosTaken) + ".png"
	var err = image.save_png(photo_path)
	
	if err == OK:
		print("Photo saved to:", photo_path)
	else:
		print("Failed to save photo:", err)
	
	Hlpr.PhotosTaken += 1

func CreatePhotoDir():
	var dir = DirAccess.open("res://")
	if dir:
		if not dir.dir_exists("res://photos"):
			dir.make_dir("res://photos")

func ChangeExposure(ex: float):
	var ExposureValue = $VBoxContainer/HBoxContainer/Exposure2
	ExposureValue.text = str(ex)
