extends Control

@onready var to_album_page: Button = $Panel/VBoxContainer/ToAlbumPage
@onready var mark_page: Button = $Panel/VBoxContainer/MarkPage
@onready var image_description: RichTextLabel = $RightBackground/BannerBackground/ImageDescription
@onready var image_container: HBoxContainer = $RightBackground/BannerBackground/ImageContainer
@onready var badge_icon: TextureRect = $RightBackground/BannerBackground/BadgeIcon
@onready var scroll_left: Button = $RightBackground/ScrollLeft
@onready var scroll_right: Button = $RightBackground/ScrollRight

const META_DIR := "user://photo_json"

var subject_photos: Array = []
var current_photo_index: int = 0

func _ready():
	GameState.photo_badge_selected.connect(_mark_photo_and_clear_others)
	_load_all_photos_for_subject()
	_load_selected_photo()
	_show_prompt_dialogue()
	_update_mark_page_button()  # <-- Added: disable/enable mark_page on ready
	
	to_album_page.pressed.connect(_on_to_album_page_pressed)
	mark_page.pressed.connect(_on_to_evaluation_page_pressed)
	scroll_left.pressed.connect(_on_scroll_left_pressed)
	scroll_right.pressed.connect(_on_scroll_right_pressed)

func _on_mark_page_pressed():
	_mark_photo_and_clear_others()

func _mark_photo_and_clear_others():
	print("==> _mark_photo_and_clear_others started")
	var selected_meta = GameState.selected_photo_meta
	var selected_path = GameState.selected_photo_path
	var selected_subject = selected_meta.get("subject_name", null)

	if selected_subject == null:
		printerr("Selected photo has no subject_name")
		return

	var selected_json_name = selected_path.get_file().replace(".png", ".json")
	print("Selected photo:", selected_json_name)
	print("Subject name:", selected_subject)

	# Update JSON badge files on disk
	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Could not open metadata directory.")
		return

	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".json"):
			continue

		var file_path = META_DIR + "/" + file_name
		print("--- Checking file:", file_path)

		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()

			var data = JSON.parse_string(text)
			if typeof(data) == TYPE_DICTIONARY:
				var subject = data.get("subject_name", "")
				var existing_badge = data.get("badge", false)
				print(" - subject_name:", subject)
				print(" - existing badge:", existing_badge)

				if subject == selected_subject:
					var is_current = file_name == selected_json_name
					print(" - Matches selected subject.")
					print(" - Is current file?:", is_current)

					if existing_badge != is_current:
						data["badge"] = is_current
						var out_file = FileAccess.open(file_path, FileAccess.WRITE)
						if out_file:
							out_file.store_string(JSON.stringify(data, "\t"))
							out_file.close()
							print(" - Updated badge to", is_current, "in", file_name)
						else:
							printerr(" - Failed to open for write:", file_path)
					else:
						print(" - Badge already correct. No write needed.")
				else:
					print(" - Different subject. Skipping.")
			else:
				printerr(" - Failed to parse JSON or data is not a dictionary in", file_name)
		else:
			printerr(" - Failed to open for read:", file_path)

	dir.list_dir_end()

	print("Reloading in-memory photo data after badge update...")
	_load_all_photos_for_subject()
	_load_selected_photo()

	print("Finished badge update.")
	call_deferred("_delayed_update_button")


func _load_selected_photo():

	for child in image_container.get_children():
		child.queue_free()

	var image_path: String = GameState.selected_photo_path
	var meta: Dictionary = GameState.selected_photo_meta

	if not image_path or not FileAccess.file_exists(image_path):
		printerr("No valid image to display.")
		return

	var image = Image.new()
	if image.load(image_path) != OK:
		printerr("Failed to load image: ", image_path)
		return

	var texture = ImageTexture.create_from_image(image)

	var overlay_container = MarginContainer.new()
	overlay_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_container.custom_minimum_size = Vector2(600, 600)

	var image_node = TextureRect.new()
	image_node.texture = texture
	image_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_node.size_flags_vertical = Control.SIZE_EXPAND_FILL

	overlay_container.add_child(image_node)
	image_container.add_child(overlay_container)

	badge_icon.visible = false  # default to hidden

	var photo_json_path = image_path.get_file().replace(".png", ".json")
	photo_json_path = META_DIR + "/" + photo_json_path

	if FileAccess.file_exists(photo_json_path):
		var file = FileAccess.open(photo_json_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var result = json.parse(text)
		if result == OK:
			var data: Dictionary = json.data
			if data.get("badge", false) == true:
				badge_icon.visible = true
		else:
			printerr("JSON parse failed: ", json.get_error_message())

	if meta.has("description"):
		image_description.bbcode_enabled = true
		image_description.text = "[font_size=44][b]" + meta.get("subject_name", "Unknown") + "[/b][/font_size]\n\n" + meta["description"]
	else:
		image_description.text = "No description found."

func _show_prompt_dialogue():
	var dialogue_res = load("res://dialogue/view_page_prompt.dialogue")
	if dialogue_res:
		CustomDialogueManager.show_dialogue_balloon(dialogue_res, "start")

func _on_to_album_page_pressed():
	SceneRouter.reset_current_scene()
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
	
func _on_to_evaluation_page_pressed():
	# Added safety: only go if at least one photo marked
	if _any_photo_marked():
		SceneRouter.goto_scene("res://scenes/evaluation_page.tscn")
	else:
		print("Please mark at least one photo before proceeding.")

func _load_all_photos_for_subject():
	var selected_meta = GameState.selected_photo_meta
	var subject_name = selected_meta.get("subject_name", "")
	if subject_name == "":
		printerr("No subject name found in selected meta.")
		return

	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Failed to open metadata directory.")
		return

	subject_photos.clear()
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path = META_DIR + "/" + file_name
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				file.close()
				if typeof(data) == TYPE_DICTIONARY and data.get("subject_name", "") == subject_name:
					var image_path = "user://photos/" + file_name.replace(".json", ".png")
					if FileAccess.file_exists(image_path):
						subject_photos.append({
							"meta": data,
							"path": image_path
						})
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort for consistency
	subject_photos.sort_custom(func(a, b): return a["path"] < b["path"])

	# Find index of currently selected photo
	current_photo_index = subject_photos.find(subject_photos.filter(func(p): return p["path"] == GameState.selected_photo_path).front())
	
func _on_scroll_left_pressed():
	if subject_photos.size() == 0:
		return

	current_photo_index = (current_photo_index - 1 + subject_photos.size()) % subject_photos.size()
	_load_photo_by_index()

func _on_scroll_right_pressed():
	if subject_photos.size() == 0:
		return

	current_photo_index = (current_photo_index + 1) % subject_photos.size()
	_load_photo_by_index()

func _load_photo_by_index():
	var entry = subject_photos[current_photo_index]
	GameState.selected_photo_path = entry["path"]
	GameState.selected_photo_meta = entry["meta"]
	_load_selected_photo()

func _update_mark_page_button() -> void:
	var any_marked = _any_photo_marked()
	print("_update_mark_page_button called. Any photo marked? ", any_marked)
	mark_page.disabled = not any_marked
	print("mark_page.disabled set to ", mark_page.disabled)

# --- NEW function to check if any photo is marked with badge: true ---
func _any_photo_marked() -> bool:
	print("Checking if any photo is marked (badge = true)...")
	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Failed to open metadata directory for badge check.")
		return false

	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".json"):
			continue

		var file_path = META_DIR + "/" + file_name
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var data = JSON.parse_string(text)
			if typeof(data) == TYPE_DICTIONARY:
				var badge = data.get("badge", false)
				print(" - File:", file_name, "badge:", badge)
				if badge == true:
					dir.list_dir_end()
					print("Found a photo marked with badge = true.")
					return true
	dir.list_dir_end()
	print("No photos marked with badge = true found.")
	return false

	
func _delayed_update_button() -> void:
	print("_delayed_update_button started, waiting 0.1 seconds...")
	await get_tree().create_timer(0.1).timeout
	print("_delayed_update_button timer finished, updating UI...")
	_load_all_photos_for_subject()
	_load_selected_photo()
	_update_mark_page_button()
	print("_delayed_update_button finished.")
	
