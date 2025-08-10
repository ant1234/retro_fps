extends Node

signal photo_badge_selected

var player_name: String = ""
var selected_stage := ""
var confirmed_stage := false
var photo_count: int = 0
var album_subject_name: String = ""
var album_subject_count: int = 0
var selected_photo_path := ""
var selected_photo_meta := {}
var selected_photos := []  # or load it from somewhere else if needed
var subject_name: String = ""
var size_score: int = 0
var pose_score: int = 0
var rarity_score = 0
var bonus_score: int = 0
var total_score: int = 0
var size_previous_score: int = 0
var pose_previous_score: int = 0
var rarity_previous_score = 0
var bonus_previous_score: int = 0
var total_previous_score: int = 0

var prev_size_score = null
var prev_pose_score = null
var prev_rarity_score = null
var prev_bonus_score = null
var prev_total_score = null


var intro_dialogue_shown := false
var returning_from_totals := false
var control_room_dialogue_shown := false


func set_selected_stage(stage_name: String) -> void:
	selected_stage = stage_name

func set_confirmed_stage(value: bool) -> void:
	confirmed_stage = value
	
func confirm_photo_selection(choice) -> void:
	print("User confirmed selection:", choice)
	if selected_photo_path != "":
		var photo_filename = selected_photo_path.get_file()
		var photo_json_path = "user://photo_json/" + photo_filename.replace(".png", ".json")

		if FileAccess.file_exists(photo_json_path):
			var file = FileAccess.open(photo_json_path, FileAccess.READ)
			var text = file.get_as_text()
			file.close()

			var json = JSON.new()
			var result = json.parse(text)
			if result == OK:
				var data: Dictionary = json.data
				data["badge"] = choice

				var amended_data = json.stringify(data, "\t")

				file = FileAccess.open(photo_json_path, FileAccess.WRITE)
				file.store_string(amended_data)
				file.close()

				print("Updated badge to", choice, "in:", photo_json_path)

				# ✅ ADD THIS TO CLEAR OTHER BADGES
				if choice:
					emit_signal("photo_badge_selected")

			else:
				printerr("Failed to parse JSON for photo:", selected_photo_path)
		else:
			printerr("Metadata file not found for photo:", selected_photo_path)

		# Reload to reflect badge change in UI
		var view_page = get_tree().get_current_scene()
		if view_page and view_page.has_method("_load_selected_photo"):
			view_page._load_selected_photo()


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
	
	
func _to_string():
	return "[subject_name: %s, size: %d, pose: %d, bonus: %d, rarity: %f]" % [subject_name, size_score, pose_score, bonus_score, rarity_score]
