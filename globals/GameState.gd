extends Node

var player_name: String = ""
var selected_stage := ""
var confirmed_stage := false
var photo_count: int = 0
var album_subject_name: String = ""
var album_subject_count: int = 0
var selected_photo_path := ""
var selected_photo_meta := {}

var control_room_dialogue_shown := false

func set_selected_stage(stage_name: String) -> void:
	selected_stage = stage_name

func set_confirmed_stage(value: bool) -> void:
	confirmed_stage = value
