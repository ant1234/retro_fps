extends Node3D
@onready var viewport_camera: Camera3D = $CameraEOS/CameraViewport/ViewportCamera
@onready var main_camera = $"../../../../.."

func _process(delta):
	viewport_camera.global_transform = main_camera.global_transform
