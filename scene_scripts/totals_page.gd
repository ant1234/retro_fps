extends Control

@onready var report_subjects_number: Label = $MainBackground/BannerBackground/ReportSubjectsNumber
@onready var report_score_number: Label = $MainBackground/BannerBackground/ReportScoreNumber

func _ready():
	update_totals()

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

			if json_data and typeof(json_data) == TYPE_DICTIONARY and json_data.has("total"):
				total_score += int(json_data["total"])
				photo_count += 1

		index += 1

	# Update UI
	report_subjects_number.text = str(photo_count)
	report_score_number.text = str(total_score) + " pts"
