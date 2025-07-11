extends Node

var player_name: String = ""
var selected_stage := ""
var confirmed_stage := false

func set_selected_stage(stage_name: String) -> void:
	selected_stage = stage_name

func set_confirmed_stage(value: bool) -> void:
	confirmed_stage = value
