extends Node

@onready var previous_photo: Panel = $RightBackground/BannerBackground/PreviousPhoto
@onready var current_photo: Panel = $RightBackground/BannerBackground/CurrentPhoto
@onready var previous_text: Label = $RightBackground/BannerBackground/PreviousText
@onready var current_text: Label = $RightBackground/BannerBackground/CurrentText
@onready var size: Label = $RightBackground/BannerBackground/Size
@onready var size_previous_score: Label = $RightBackground/BannerBackground/SizePreviousScore
@onready var size_current_score: Label = $RightBackground/BannerBackground/SizeCurrentScore
@onready var pose: Label = $RightBackground/BannerBackground/Pose
@onready var pose_previous_score: Label = $RightBackground/BannerBackground/PosePreviousScore
@onready var pose_current_score: Label = $RightBackground/BannerBackground/PoseCurrentScore
@onready var rarity: Label = $RightBackground/BannerBackground/Rarity
@onready var rarity_previous_score: Label = $RightBackground/BannerBackground/RarityPreviousScore
@onready var rarity_current_score: Label = $RightBackground/BannerBackground/RarityCurrentScore
@onready var bonus: Label = $RightBackground/BannerBackground/Bonus
@onready var bonus_previous_score: Label = $RightBackground/BannerBackground/BonusPreviousScore
@onready var bonus_current_score: Label = $RightBackground/BannerBackground/BonusCurrentScore
@onready var total: Label = $RightBackground/BannerBackground/Total
@onready var total_previous_score: Label = $RightBackground/BannerBackground/TotalPreviousScore
@onready var total_current_score: Label = $RightBackground/BannerBackground/TotalCurrentScore
@onready var subject_name_label: Label = $RightBackground/BannerBackground/SubjectName

var badge_photos: Array = []
var current_index: int = 0
var current_step: int = 0
var current_total: int = 0
var current_data: Dictionary

const META_DIR := "user://photo_json"
const PHOTO_DIR := "user://photos"
const DIALOGUE_PATH := "res://dialogue/evaluation.dialogue"

func _ready():
	DialogueManager.game_states.clear()
	DialogueManager.game_states.append(self)  # ✅ Add self so [do function()] works
	DialogueManager.game_states.append(GameState)

	DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

	_load_badged_photos()

	if badge_photos.size() > 0:
		_evaluate_next_photo()
	else:
		_show_dialogue("empty")

func _on_dialogue_finished(_res = null):
	current_index += 1
	_evaluate_next_photo()

func _load_badged_photos():
	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Could not open metadata directory.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path = META_DIR + "/" + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()

				var json = JSON.new()
				if json.parse(text) == OK:
					var data: Dictionary = json.data
					if data.get("badge", false) == true:
						data["__file_path"] = file_path
						data["__image_file"] = file_name.replace(".json", ".png")
						badge_photos.append(data)
		file_name = dir.get_next()
	dir.list_dir_end()

func _evaluate_next_photo():
	if current_index >= badge_photos.size():
		_show_dialogue("complete")
		return

	current_data = badge_photos[current_index]
	current_total = 0
	_clear_ui()
	_load_current_photo_image()

	var subject = current_data.get("subject_name", "Unknown Subject")
	subject_name_label.text = subject
	GameState.subject_name = subject

	var size_score = 370
	GameState.size_score = size_score
	current_total += size_score

	var pose_score = 350
	GameState.pose_score = pose_score
	current_total += pose_score

	var rarity_mult = current_data.get("rarity", 1)
	GameState.rarity_mult = rarity_mult
	current_total *= rarity_mult

	var bonus_score = 230
	GameState.bonus_score = bonus_score
	current_total += bonus_score

	GameState.total_score = current_total
	_show_dialogue("reveal_all")

func _clear_ui():
	size.visible = false
	pose.visible = false
	rarity.visible = false
	bonus.visible = false

	size_current_score.text = ""
	pose_current_score.text = ""
	rarity_current_score.text = ""
	bonus_current_score.text = ""
	total_current_score.text = ""

	for child in current_photo.get_children():
		child.queue_free()

func _load_current_photo_image():
	var image_filename = current_data.get("__image_file", "")
	if image_filename == "":
		printerr("Missing image filename.")
		return

	var image_path = PHOTO_DIR + "/" + image_filename
	if not FileAccess.file_exists(image_path):
		printerr("Photo file not found: ", image_path)
		return

	var img = Image.new()
	var err = img.load(image_path)
	if err != OK:
		printerr("Failed to load image: ", image_path)
		return

	var tex = ImageTexture.create_from_image(img)
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
	tex_rect.size = Vector2(330, 330)
	tex_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = 0
	tex_rect.size_flags_vertical = 0
	tex_rect.anchor_left = 0.0
	tex_rect.anchor_top = 0.0
	tex_rect.anchor_right = 0.0
	tex_rect.anchor_bottom = 0.0
	tex_rect.position = Vector2.ZERO
	current_photo.add_child(tex_rect)

func _show_dialogue(key: String):
	var res = load(DIALOGUE_PATH)
	if res and DialogueManager:
		DialogueManager.show_dialogue_balloon(res, key, [self, GameState])
	else:
		printerr("Failed to load dialogue resource or DialogueManager missing.")

func show_size_score():
	print("✅ YES! show_size_score.")
	size.visible = true
	size_current_score.text = str(GameState.size_score)

func show_pose_score():
	print("✅ YES! show_pose_score.")
	pose.visible = true
	pose_current_score.text = str(GameState.pose_score)

func show_rarity_score():
	print("✅ YES! show_rarity_score.")
	rarity.visible = true
	rarity_current_score.text = str(GameState.rarity_mult) + "x"

func show_bonus_score():
	print("✅ YES! show_bonus_score.")
	bonus.visible = true
	bonus_current_score.text = str(GameState.bonus_score) + "pts"

func show_total_score():
	print("✅ YES! show_total_score.")
	total.visible = true
	total_current_score.text = str(GameState.total_score)
