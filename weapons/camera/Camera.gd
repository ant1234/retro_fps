extends Control

var FileName = "photo"
@onready var main_camera : Camera3D = $"../../../../../../../.."

func _ready():
	CreatePhotoDir()

func SavePhoto():
	print("--- SavePhoto() called ---")

	# Get photo viewport + camera
	var camera_viewport: Viewport = $".."
	var viewport_camera: Camera3D = $"../ViewportCamera"

	if viewport_camera == null:
		push_error("No viewport camera found")
		return
	print("Viewport camera found:", viewport_camera.name)

	# Hide HUD reticle if exists
	var reticle := get_node_or_null("../HUD/Crosshairs")
	var reticle_was_visible := false
	if reticle:
		reticle_was_visible = reticle.visible
		reticle.visible = false
		print("Hid reticle for screenshot")

	await get_tree().process_frame
	print("Waited 1 frame before capture")

	# Capture from photo viewport (not main)
	var texture := camera_viewport.get_texture()
	if texture == null:
		print("❌ Camera viewport has no texture — cannot capture")
		return
	var image: Image = texture.get_image()
	print("Captured image size:", image.get_size())

	# Restore reticle
	if reticle:
		reticle.visible = reticle_was_visible

	# Save PNG
	var photo_index = Helper.PhotosTaken
	var photo_base_path = "user://photos/photo" + str(photo_index)
	var err = image.save_png(photo_base_path + ".png")
	if err != OK:
		print("❌ Failed to save image:", err)
		return
	print("✅ Saved photo:", photo_base_path + ".png")

	# Metadata
	Helper.LastPhotoMetadata = {}
	var screen_size = camera_viewport.get_visible_rect().size
	var from = viewport_camera.project_ray_origin(screen_size / 2)
	var to = from + viewport_camera.project_ray_normal(screen_size / 2) * 100.0

	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = viewport_camera.get_world_3d().direct_space_state.intersect_ray(query)
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

			Helper.LastPhotoMetadata["size"]  = CalculateSubjectSizeScore(subject_node, viewport_camera, screen_size)
			Helper.LastPhotoMetadata["pose"]  = CalculateSubjectPoseScore(subject_node, viewport_camera)
			Helper.LastPhotoMetadata["bonus"] = CalculateSubjectBonusScore(subject_node, viewport_camera)

	# Always save JSON
	var json_base_path = "user://photo_json/photo" + str(photo_index)
	var file = FileAccess.open(json_base_path + ".json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(Helper.LastPhotoMetadata)
		file.store_string(json_string)
		file.close()
		print("✅ Saved metadata JSON:", json_base_path + ".json")

	Helper.PhotosTaken += 1
	print("--- SavePhoto() finished ---")

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

	# Use dot product to determine alignment
	var dot = fish_forward_flat.dot(to_camera_flat)  # -1 front-facing, 0 side-on, +1 swimming away

	var score: int
	if dot >= 0.0:
		# From side-on to swimming away (dot: 0 to 1)
		score = int(lerp(1000, 100, dot))
	else:
		# From side-on to front-facing (dot: 0 to -1)
		score = int(lerp(1000, 500, -dot))

	return score

func CalculateSubjectBonusScore(subject_node: Node3D, camera: Camera3D) -> int:
	var bonus := 0
	var screen_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var center_rect_size: Vector2 = Vector2(512, 512)
	var center_rect := Rect2((screen_size - center_rect_size) / 2, center_rect_size)

	var cam_origin := camera.global_transform.origin
	var cam_forward := -camera.global_transform.basis.z.normalized()

	var player := get_node_or_null("../../../../../../../../..") # root player

	var player_origin: Vector3 = player.global_transform.origin if player else cam_origin

	var fish_nodes := get_tree().get_nodes_in_group("fish")
	for fish in fish_nodes:
		if fish == subject_node or not fish.is_inside_tree():
			continue

		# Optional: Only count fish within 10 meters of player
		var distance_to_player: float = fish.global_transform.origin.distance_to(player_origin)
		if distance_to_player > 10.0:
			continue

		var to_fish: Vector3 = (fish.global_transform.origin - cam_origin).normalized()
		var facing := cam_forward.dot(to_fish)

		if facing <= 0:
			continue  # Fish is behind the camera

		var screen_pos = camera.unproject_position(fish.global_transform.origin)

		if screen_pos.x < 0 or screen_pos.y < 0 or screen_pos.x > screen_size.x or screen_pos.y > screen_size.y:
			continue  # Off-screen

		if center_rect.has_point(screen_pos):
			print("Fish:", fish.name, " screen_pos:", screen_pos, " distance:", distance_to_player)
			bonus += 1

	return min(bonus, 10)
