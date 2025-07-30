extends Control

var FileName = "photo"

func _ready():
	CreatePhotoDir()

func SavePhoto():
	var camera_viewport: Viewport = $".."
	var overlay := camera_viewport.get_node("CameraOverlay")
	var overlay_was_visible: bool = overlay.visible

	# Hide overlay for screenshot
	overlay.visible = false
	await get_tree().process_frame

	# Capture photo
	var image: Image = camera_viewport.get_texture().get_image()
	overlay.visible = overlay_was_visible

	var photo_index = Helper.PhotosTaken
	var photo_base_path = "user://photos/photo" + str(photo_index)
	var err = image.save_png(photo_base_path + ".png")
	if err != OK:
		return

	Helper.LastPhotoMetadata = {}
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

				var size_score = CalculateSubjectSizeScore(subject_node, viewport_camera, screen_size)
				Helper.LastPhotoMetadata["size"] = size_score

				var pose_score = CalculateSubjectPoseScore(subject_node, viewport_camera)
				Helper.LastPhotoMetadata["pose"] = pose_score

	# Save metadata to JSON
	if Helper.LastPhotoMetadata:
		for key in Helper.LastPhotoMetadata.keys():
			print("  ", key, ": ", Helper.LastPhotoMetadata[key])
		
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
	
func CalculateSubjectSizeScore(subject_node: Node3D, camera: Camera3D, screen_size: Vector2) -> int:
	var parent_node = subject_node.get_parent()
	var shape_node: CollisionShape3D = parent_node.get_node_or_null("CollisionShape3D")
	if shape_node == null:
		shape_node = parent_node.find_child("CollisionShape3D", true, false)

	if shape_node and shape_node.shape is BoxShape3D:
		var box = shape_node.shape as BoxShape3D
		var extents = box.extents
		var basis = parent_node.global_transform.basis
		var origin = parent_node.global_transform.origin

		var corners = []
		for x_sign in [-1, 1]:
			for y_sign in [-1, 1]:
				for z_sign in [-1, 1]:
					var local = Vector3(x_sign * extents.x, y_sign * extents.y, z_sign * extents.z)
					var world = origin + basis * local
					corners.append(world)

		var projected = []
		var all_visible = true
		for world_point in corners:
			var screen_point = camera.unproject_position(world_point)
			if screen_point.x < 0 or screen_point.x > screen_size.x or screen_point.y < 0 or screen_point.y > screen_size.y:
				all_visible = false
			projected.append(screen_point)

		var min_x = INF
		var max_x = -INF
		for p in projected:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
		var horizontal_width = max_x - min_x
		var width_ratio = horizontal_width / screen_size.x

		var size_score = 0
		if all_visible:
			if width_ratio > 1.1:
				size_score = 500
			elif width_ratio >= 0.8:
				size_score = 1000
			elif width_ratio >= 0.5:
				size_score = 600
			elif width_ratio >= 0.3:
				size_score = 400
			elif width_ratio >= 0.1:
				size_score = 200
			else:
				size_score = 50
		else:
			size_score = 50

		return size_score
	
	return 0
	
func CalculateSubjectPoseScore(subject_node: Node3D, camera: Camera3D) -> int:
	var fish_forward: Vector3 = subject_node.global_transform.basis.z.normalized()
	var to_camera: Vector3 = (camera.global_position - subject_node.global_position).normalized()

	# Flatten vectors to XZ plane
	var fish_forward_flat = Vector3(fish_forward.x, 0, fish_forward.z).normalized()
	var to_camera_flat = Vector3(to_camera.x, 0, to_camera.z).normalized()

	var dot = fish_forward_flat.dot(to_camera_flat)

	if dot < -0.9:
		return 500  # Front-facing
	elif dot > 0.9:
		return 100  # Swimming away
	else:
		return 1000  # Side-on (perfect)
