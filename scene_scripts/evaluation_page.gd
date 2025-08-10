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

# 🆕 Last evaluated persistent tracking
var last_evaluated: Array = []
const LAST_EVALUATED_PATH := "user://photo_json/last_evaluated.json"

const META_DIR := "user://photo_json"
const PHOTO_DIR := "user://photos"
const DIALOGUE_PATH := "res://dialogue/evaluation.dialogue"

func _ready():
	DialogueManager.game_states.clear()
	DialogueManager.game_states.append(self)
	DialogueManager.game_states.append(GameState)

	DialogueManager.dialogue_ended.connect(_on_dialogue_finished)

	_load_last_evaluated() # 🆕 load persistent scores
	_load_badged_photos()

	if badge_photos.size() > 0:
		_evaluate_next_photo()
	else:
		_show_dialogue("empty")

func _on_dialogue_finished(_res = null):
	# 🆕 After dialogue finishes, update persistent best score
	_update_last_evaluated()
	current_index += 1
	_evaluate_next_photo()

func _load_last_evaluated():
	if FileAccess.file_exists(LAST_EVALUATED_PATH):
		var file = FileAccess.open(LAST_EVALUATED_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_ARRAY:
				last_evaluated = json.data
	else:
		last_evaluated = []

func _save_last_evaluated():
	var file = FileAccess.open(LAST_EVALUATED_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(last_evaluated, "\t"))
		file.close()

func _load_badged_photos():
	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Could not open metadata directory.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name != "last_evaluated.json": # avoid loading persistent file
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
		SceneRouter.goto_scene("res://scenes/totals_page.tscn")
		return

	current_data = badge_photos[current_index]
	if current_data.is_empty():
		printerr("Warning: current_data is empty at index ", current_index)
		_show_dialogue("complete")
		return

	current_total = 0
	_clear_ui()
	_load_current_photo_image()

	var subject = current_data.get("subject_name", "Unknown Subject")
	subject_name_label.text = subject
	GameState.subject_name = subject

	var size_score = current_data.get("size", 0)
	var pose_score = current_data.get("pose", 0)
	var rareness_score = current_data.get("rareness", 0)
	var bonus_mult = current_data.get("bonus", 1)

	GameState.size_score = size_score
	GameState.pose_score = pose_score
	GameState.rarity_score = rareness_score * 100
	GameState.bonus_score = bonus_mult

	current_total = (size_score + pose_score + (rareness_score * 100)) * bonus_mult
	GameState.total_score = current_total
	current_data["total"] = current_total

	# Save back to original photo JSON
	var file_path = current_data.get("__file_path", "")
	if file_path != "":
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(current_data, "\t"))
			file.close()

	# 🆕 Load and show previous best if it exists
	_show_previous_best(subject)

	_show_dialogue("reveal_all")

func _show_previous_best(subject: String):
	var prev = null
	for entry in last_evaluated:
		if entry.get("subject_name", "") == subject:
			prev = entry
			break
	if prev:
		# Set labels for previous score
		size.visible = true
		pose.visible = true
		rarity.visible = true
		bonus.visible = true
		total.visible = true
		previous_photo.visible = true
		previous_text.visible = true
		size_previous_score.text = str(prev.get("size", 0))
		pose_previous_score.text = str(prev.get("pose", 0))
		rarity_previous_score.text = str(prev.get("rareness", 0) * 100)
		bonus_previous_score.text = str(prev.get("bonus", 1)) + "x"
		total_previous_score.text = str(prev.get("total", 0)) + "pts"

		# Load previous photo image
		for child in previous_photo.get_children():
			child.queue_free()
		var img_path = PHOTO_DIR + "/" + prev.get("__image_file", "")
		print('Image path : ', img_path)
		if FileAccess.file_exists(img_path):
			print('Image exists')
			var img = Image.new()
			if img.load(img_path) == OK:
				print('Image loaded')
				var tex = ImageTexture.create_from_image(img)
				var tex_rect = TextureRect.new()
				tex_rect.texture = tex
				tex_rect.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
				tex_rect.size = Vector2(330, 330)
				tex_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
				previous_photo.add_child(tex_rect)

func _update_last_evaluated():
	var subject = current_data.get("subject_name", "")
	if subject == "":
		return

	var existing_index = -1
	for i in range(last_evaluated.size()):
		if last_evaluated[i].get("subject_name", "") == subject:
			existing_index = i
			break

	if existing_index == -1:
		last_evaluated.append(current_data.duplicate(true))
	elif current_total > last_evaluated[existing_index].get("total", 0):
		last_evaluated[existing_index] = current_data.duplicate(true)

	_save_last_evaluated()

func _clear_ui():
	size.visible = false
	pose.visible = false
	rarity.visible = false
	bonus.visible = false
	total.visible = false
	size_current_score.text = ""
	pose_current_score.text = ""
	rarity_current_score.text = ""
	bonus_current_score.text = ""
	total_current_score.text = ""
	size_previous_score.text = ""
	pose_previous_score.text = ""
	rarity_previous_score.text = ""
	bonus_previous_score.text = ""
	total_previous_score.text = ""
	for child in current_photo.get_children():
		child.queue_free()
	for child in previous_photo.get_children():
		child.queue_free()

func _load_current_photo_image():
	var image_filename = current_data.get("__image_file", "")
	if image_filename == "":
		return
	var image_path = PHOTO_DIR + "/" + image_filename
	if not FileAccess.file_exists(image_path):
		return
	var img = Image.new()
	if img.load(image_path) != OK:
		return
	var tex = ImageTexture.create_from_image(img)
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.expand_mode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE
	tex_rect.size = Vector2(330, 330)
	tex_rect.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
	current_photo.add_child(tex_rect)

func _show_dialogue(key: String):
	var res = load(DIALOGUE_PATH)
	if res and DialogueManager:
		if typeof(GameState) == TYPE_OBJECT and GameState:
			DialogueManager.game_states.clear()
			DialogueManager.game_states.append({"self": self})
			DialogueManager.game_states.append({"GameState": GameState})
			await get_tree().process_frame
			DialogueManager.show_dialogue_balloon(res, key)

func show_size_score():
	size.visible = true
	size_current_score.text = str(GameState.size_score)

func show_pose_score():
	pose.visible = true
	pose_current_score.text = str(GameState.pose_score)

func show_rarity_score():
	rarity.visible = true
	rarity_current_score.text = str(GameState.rarity_score)

func show_bonus_score():
	bonus.visible = true
	bonus_current_score.text = str(GameState.bonus_score) + "x"

func show_total_score():
	total.visible = true
	total_current_score.text = str(GameState.total_score) + "pts"
