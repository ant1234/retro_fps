extends Node

var player_name: String = ""
var selected_stage := ""
var confirmed_stage := false
var photo_count: int = 0
var album_subject_name: String = ""
var album_subject_count: int = 0
var selected_photo_path := ""
var selected_photo_meta := {}
var selected_photos := []

var control_room_dialogue_shown := false

func set_selected_stage(stage_name: String) -> void:
	selected_stage = stage_name

func set_confirmed_stage(value: bool) -> void:
	confirmed_stage = value
	
func confirm_photo_selection(choice) -> void:
	print("User confirmed selection:", choice)
	if choice:
		if selected_photo_path != "":
			var new_photo = {
				"path": selected_photo_path,
				"meta": selected_photo_meta,
				"badge": true
			}
			GameState.selected_photos.append(new_photo)
			print("photo array:", GameState.selected_photos)

			# Refresh photo display with badge
			var view_page = get_tree().get_current_scene()
			if view_page and view_page.has_method("_load_selected_photo"):
				view_page._load_selected_photo()
	else:
		pass


func go_to_album() -> void:
	print("Going back to album")
	var album_scene = load("res://scenes/album_page.tscn")
	if album_scene:
		get_tree().change_scene_to_packed(album_scene)
	
func is_photo_selected(path: String) -> bool:
	for photo in selected_photos:
		if photo["path"] == path:
			return true
	return false
