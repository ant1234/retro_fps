extends Control

var CameraRollPath = "res://photos"
var PhotosName = "photo"
var NumPhoto = 0
@export var GalleryThumbnailSize := Vector2(640, 360)
@export var PhotoSize := Vector2(1280, 720)

@onready var CameraRoll = $"."
@onready var SinglePhoto = $PhotoBrowser
@onready var LB = $PhotoBrowser/VBoxContainer/SinglePhoto/Left
@onready var Hlpr = $"/root/Helper"

@onready var Scroller = $GalContainer/Scroller
@onready var Gallery = $GalContainer/Scroller/Gallery
@onready var GalContainer = $GalContainer
@onready var GalleryTexture = preload("res://DIGITAL_CAMERA/Camera3D/GalleryTexture/GalleryTexture.tscn")
@onready var PhotoBrowser = $PhotoBrowser


func _ready():
	CameraRoll.hide()
	MakeGallery()

func _input(_event):
	if Input.is_action_just_pressed("camera_roll"):
		ShowHideMenu()

func LoadPhoto(Photo: TextureRect, num: int, ImageScale):
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("photos/photo" + str(num) + ".png"):
		var texture = load_external_tex("res://photos/photo" + str(num) + ".png", ImageScale)
		Photo.texture = texture
	else:
		print("Error opening the photo folder")

func load_external_tex(path: String, scale: Vector2) -> Texture2D:
	var tex_file = FileAccess.open(path, FileAccess.READ)
	var buffer = tex_file.get_buffer(tex_file.get_length())

	var img = Image.new()
	img.load_png_from_buffer(buffer)
	var imgtex = ImageTexture.new()
	imgtex.create_from_image(img)
	imgtex.set_size_override(scale)

	tex_file.close()
	return imgtex

func MakeGallery():
	var Photos = Hlpr.PhotosTaken
	var GalleryCount = Gallery.get_child_count()

	if Photos != GalleryCount:
		var PhotosToAdd = Photos - GalleryCount
		for p in range(PhotosToAdd):
			var PhotoIndex = p + GalleryCount
			var TexRex = GalleryTexture.instantiate()
			TexRex.Number = PhotoIndex
			Gallery.add_child(TexRex)
			TexRex.connect("ClickedOn", Callable(self, "GalleryMouseClick"))
			TexRex.set_z_index(0)
			LoadPhoto(TexRex, PhotoIndex, GalleryThumbnailSize)

func GalleryMouseClick(PhotoNumber: int):
	GoToPhotoBrowser(PhotoNumber)
	NumPhoto = PhotoNumber

func ShowHideMenu():
	if CameraRoll.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		CameraRoll.hide()
		get_tree().paused = false
	else:
		get_tree().paused = true
		CameraRoll.show()
		MakeGallery()
		#LB.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func CountUp():
	NumPhoto += 1
	if NumPhoto > Hlpr.PhotosTaken:
		NumPhoto = 1

func CountDown():
	NumPhoto -= 1
	if NumPhoto == 0:
		NumPhoto = Hlpr.PhotosTaken

func _on_Left_button_down():
	CountDown()
	LoadPhoto(SinglePhoto, NumPhoto, Vector2(1920, 1080))

func _on_right_button_down():
	CountUp()
	LoadPhoto(SinglePhoto, NumPhoto, Vector2(1920, 1080))

func _on_GalleryButton_pressed():
	GoToGallery()

func _on_BackButton_pressed():
	GoToPhotoBrowser(NumPhoto)

func GoToPhotoBrowser(PhotoNumber: int = 0):
	GalContainer.hide()
	PhotoBrowser.show()
	LoadPhoto(SinglePhoto, PhotoNumber, Vector2(1920, 1080))

func GoToGallery():
	PhotoBrowser.hide()
	GalContainer.show()

func _on_Scroller_item_rect_changed():
	var GalleryColumns = round(Scroller.size.x / 250)
	Gallery.set_columns(GalleryColumns)
