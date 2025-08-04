extends Control

@onready var report_subjects_number: Label = $MainBackground/BannerBackground/ReportSubjectsNumber
@onready var report_score_number: Label = $MainBackground/BannerBackground/ReportScoreNumber

func _ready():
	update_totals()
	start_dialogue()

func update_totals():
	var total_score := 0
	var photo_count := 0
	var index := 0

	while true:
		var file_path := "user://photo_json/photo%d.json" % index
		if not FileAccess.file_exists(file_path):
			break

		var file := FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_data = JSON.parse_string(file.get_as_text())
			file.close()

			if json_data is Dictionary and json_data.get("badge", false) == true:
				# Add to total and count
				total_score += int(json_data.get("total", 0))
				photo_count += 1

				# Set badge to false
				json_data["badge"] = false

				# Write back to the file
				var write_file = FileAccess.open(file_path, FileAccess.WRITE)
				if write_file:
					write_file.store_string(JSON.stringify(json_data, "\t"))  # Pretty-print with tabs
					write_file.close()

		index += 1

	# Update UI
	report_subjects_number.text = str(photo_count) + " x"
	report_score_number.text = str(total_score) + " pts"

func start_dialogue():
	var dialogue_resource = load("res://dialogue/totals.dialogue")
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")

func return_to_control_room():
	SceneRouter.goto_scene("res://scenes/control_room_page.tscn")
