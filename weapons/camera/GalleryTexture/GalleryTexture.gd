extends TextureRect

signal ClickedOn

@onready var GalTex = $"."
var Number := 0

var BaseScale := Vector2(1, 1)
var GrowScale := Vector2(1.1, 1.1)
var GrowSpeed := 0.2

var hover_tween : Tween = null

func _on_GalleryTexture_gui_input(event):
	if event.is_action_pressed("left_click"):
		emit_signal("ClickedOn", Number)

func _on_GalleryTexture_mouse_entered():
	GalTex.z_index = 10
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(GalTex, "scale", GrowScale, GrowSpeed).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _on_GalleryTexture_mouse_exited():
	GalTex.z_index = 0
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(GalTex, "scale", BaseScale, GrowSpeed).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
