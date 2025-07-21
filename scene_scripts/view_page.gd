extends Control

@onready var to_album_page: Button = $Panel/VBoxContainer/ToAlbumPage
@onready var mark_page: Button = $Panel/VBoxContainer/MarkPage
@onready var image_description: RichTextLabel = $RightBackground/BannerBackground/ImageDescription
@onready var image_container: HBoxContainer = $RightBackground/BannerBackground/ImageContainer
@onready var badge_icon: TextureRect = $RightBackground/BannerBackground/BadgeIcon

func _ready():
	_load_selected_photo()
	_show_prompt_dialogue()
	to_album_page.pressed.connect(_on_to_album_page_pressed)

func _load_selected_photo():
	print("Loading selected photo:", GameState.selected_photo_path)

	# Clear previous children to avoid duplicates
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

	# Create container for image only
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

	# Control badge_icon visibility without moving it
	badge_icon.visible = false  # default to hidden

	var photo_json_path = image_path.get_file().replace(".png", ".json")
	photo_json_path = "user://photo_json/" + photo_json_path
	
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

	# Add description
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
	SceneRouter.goto_scene("res://scenes/album_page.tscn")
