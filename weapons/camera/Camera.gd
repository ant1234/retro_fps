extends Control

# "Camera CANON EOS 400D" (https://skfb.ly/6VsDZ) by santy is licensed under Creative Commons Attribution 
# (http://creativecommons.org/licenses/by/4.0/).

var FileName = "photo"

func _ready():
	CreatePhotoDir()

func SavePhoto():

	var camera_viewport: Viewport = $".."
	var overlay := camera_viewport.get_node("CameraOverlay")
	var overlay_was_visible: bool = overlay.visible
	
	# Hide overlay to prevent it from appearing in photo
	overlay.visible = false
	await get_tree().process_frame  # Wait one frame to flush changes

	# Take photo
	var image: Image = camera_viewport.get_texture().get_image()

	# Restore overlay visibility
	overlay.visible = overlay_was_visible

	# Save the image
	var photo_index = Helper.PhotosTaken
	var photo_base_path = "user://photos/photo" + str(photo_index)
	var err = image.save_png(photo_base_path + ".png")
	if err != OK:
		return

	# Detect subject (fish)
	Helper.LastPhotoMetadata = {}  # Reset
	var viewport_camera: Camera3D = $"../ViewportCamera"
	if is_instance_valid(viewport_camera):
		var screen_size = camera_viewport.get_visible_rect().size
		var from = viewport_camera.project_ray_origin(screen_size / 2)
		var to = from + viewport_camera.project_ray_normal(screen_size / 2) * 100.0

		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		query.collide_with_areas = true
		query.collide_with_bodies = true

		var space_state = viewport_camera.get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.get("collider")
			var subject_node = collider.get_node_or_null("PhotoSubject")
			if not subject_node:
				subject_node = collider.find_child("PhotoSubject", true, false)
			if subject_node:
				Helper.LastPhotoMetadata = {
					"subject_name": subject_node.subject_name,
					"description": subject_node.description,
					"rareness": subject_node.rareness
				}
				subject_node.set_meta("_printed", true)

	# Save metadata if found
	if Helper.LastPhotoMetadata:
		var json_base_path = "user://photo_json/photo" + str(photo_index)
		var file = FileAccess.open(json_base_path + ".json", FileAccess.WRITE)

		if file:
			var json_string = JSON.stringify(Helper.LastPhotoMetadata)
			file.store_string(json_string)
			file.close()

	Helper.PhotosTaken += 1

func CreatePhotoDir():
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("user://photos"):
			dir.make_dir("user://photos")
		if not dir.dir_exists("user://photo_json"):
			dir.make_dir("user://photo_json")

func ChangeExposure(ex: float):
	var ExposureValue = $VBoxContainer/HBoxContainer/Exposure2
	ExposureValue.text = str(ex)
