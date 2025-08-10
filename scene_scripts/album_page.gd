extends Control

const PHOTOS_DIR := "user://photos"
const META_DIR := "user://photo_json"
const PHOTOS_PER_PAGE := 8

@onready var top_container: HBoxContainer = $RightBackground/BannerBackground/TopContainer
@onready var bottom_container: HBoxContainer = $RightBackground/BannerBackground/BottomContainer
@onready var scroll_left: Button = $RightBackground/ScrollLeft
@onready var scroll_right: Button = $RightBackground/ScrollRight
@onready var to_control_room: Button = $Panel/VBoxContainer/ToControlRoom
@onready var mark_page: Button = $Panel/VBoxContainer/MarkPage
@onready var preview_text: RichTextLabel = $Panel/PreviewText
@onready var preview_photo: HBoxContainer = $Panel/PreviewPhoto

var photo_data: Array = []
var current_page := 0
var total_pages := 0
var selected_photo_index := -1

var last_clicked_index := -1
var last_click_time := 0.0
const DOUBLE_CLICK_TIME := 0.8

func _ready():
	scroll_left.pressed.connect(_on_scroll_left)
	scroll_right.pressed.connect(_on_scroll_right)
	mark_page.pressed.connect(_on_to_mark_page)

	_load_photos_with_metadata()
	_display_page(0)
	_update_mark_page_button()  # Update button state on load

func _load_photos_with_metadata():
	photo_data.clear()
	var dir = DirAccess.open(META_DIR)
	if not dir:
		printerr("Failed to open photo_json directory.")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var json_path = META_DIR + "/" + file_name
			var img_path = PHOTOS_DIR + "/" + file_name.get_basename() + ".png"

			if FileAccess.file_exists(img_path):
				var file = FileAccess.open(json_path, FileAccess.READ)
				if file:
					var json = JSON.parse_string(file.get_as_text())
					if typeof(json) == TYPE_DICTIONARY:
						photo_data.append({
							"image_path": img_path,
							"meta": json
						})
		file_name = dir.get_next()
	dir.list_dir_end()

	total_pages = int(ceil(float(photo_data.size()) / PHOTOS_PER_PAGE))

func _display_page(page_index: int):
	top_container.get_children().map(func(c): c.queue_free())
	bottom_container.get_children().map(func(c): c.queue_free())

	var start = page_index * PHOTOS_PER_PAGE
	var end = min(start + PHOTOS_PER_PAGE, photo_data.size())

	for i in range(start, end):
		var photo_info = photo_data[i]
		var image = Image.new()
		var result = image.load(photo_info["image_path"])
		if result == OK:
			var texture = ImageTexture.create_from_image(image)

			var tex_rect = TextureRect.new()
			tex_rect.texture = texture
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(330, 330)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			tex_rect.name = str(i)

			# Connect click to update dialogue
			tex_rect.gui_input.connect(_on_photo_selected.bind(i))

			# Wrap in MarginContainer for spacing
			var margin = MarginContainer.new()
			margin.add_child(tex_rect)
			margin.add_theme_constant_override("margin_left", 50)
			margin.add_theme_constant_override("margin_right", 10)
			margin.add_theme_constant_override("margin_top", 10)
			margin.add_theme_constant_override("margin_bottom", 10)

			if i - start < 4:
				top_container.add_child(margin)
			else:
				bottom_container.add_child(margin)

	current_page = page_index
	_update_scroll_buttons()

func _update_scroll_buttons():
	scroll_left.disabled = current_page <= 0
	scroll_right.disabled = current_page >= total_pages - 1

func _on_scroll_left():
	if current_page > 0:
		_display_page(current_page - 1)

func _on_scroll_right():
	if current_page < total_pages - 1:
		_display_page(current_page + 1)

func _on_photo_selected(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var now := Time.get_ticks_msec() / 1000.0  # seconds

		if index == last_clicked_index and now - last_click_time <= DOUBLE_CLICK_TIME:
			var selected = photo_data[index]
			GameState.selected_photo_path = selected["image_path"]
			GameState.selected_photo_meta = selected["meta"]
			get_tree().change_scene_to_file("res://scenes/view_page.tscn")
		else:
			last_clicked_index = index
			last_click_time = now

			var selected_subject = photo_data[index]["meta"].get("subject_name", "Unknown")
			var count = _count_subject_name(selected_subject)
			GameState.album_subject_count = count
			GameState.album_subject_name = selected_subject
			selected_photo_index = index

			CustomDialogueManager.show_dialogue_balloon(
				load("res://dialogue/album_page.dialogue"),
				"photo_info"
			)
			
			# Show preview for first badge=true photo of the selected subject
			preview_photo.visible = false
			preview_text.visible = false
			preview_photo.get_children().map(func(c): c.queue_free())

			for entry in photo_data:
				if entry["meta"].get("subject_name", "") == selected_subject and entry["meta"].get("badge", false) == true:
					var image = Image.new()
					if image.load(entry["image_path"]) == OK:
						var texture = ImageTexture.create_from_image(image)

						var badge_image = TextureRect.new()
						badge_image.texture = texture
						badge_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
						badge_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
						badge_image.custom_minimum_size = Vector2(300, 300)
						badge_image.mouse_filter = Control.MOUSE_FILTER_IGNORE

						preview_photo.add_child(badge_image)
						preview_photo.visible = true
						preview_text.visible = true
						break  # Stop after first badge match

func _count_subject_name(subject: String) -> int:
	var count := 0
	for entry in photo_data:
		if entry["meta"].get("subject_name", "") == subject:
			count += 1
	return count

func _on_to_mark_page():
	if _any_photo_marked():
		SceneRouter.goto_scene("res://scenes/evaluation_page.tscn")
		
func _any_photo_marked() -> bool:
	for entry in photo_data:
		if entry["meta"].get("badge", false) == true:
			return true
	return false

func _update_mark_page_button() -> void:
	mark_page.disabled = not _any_photo_marked()
