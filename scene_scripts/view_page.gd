extends Control

@onready var to_control_room: Button = $Panel/VBoxContainer/ToControlRoom
@onready var mark_page: Button = $Panel/VBoxContainer/MarkPage
@onready var image_description: RichTextLabel = $RightBackground/BannerBackground/ImageDescription
@onready var image_container: HBoxContainer = $RightBackground/BannerBackground/ImageContainer

func _ready():
	mark_page.disabled = true
	to_control_room.disabled = true

	_load_selected_photo()
	_show_prompt_dialogue()

func _load_selected_photo():
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

	var tex_rect = TextureRect.new()
	tex_rect.texture = texture
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(600, 600)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	image_container.add_child(tex_rect)

	# Fill in the description
	if meta.has("description"):
		image_description.bbcode_enabled = true
		image_description.text = "[font_size=44][b]" + meta.get("subject_name", "Unknown") + "[/b][/font_size]\n\n" + meta["description"]
	else:
		image_description.text = "No description found."

func _show_prompt_dialogue():
	var dialogue_res = load("res://dialogue/view_page_prompt.dialogue")
	if dialogue_res:
		CustomDialogueManager.show_dialogue_balloon(dialogue_res, "view_prompt")
