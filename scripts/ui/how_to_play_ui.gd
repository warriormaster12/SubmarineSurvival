extends Control

func _ready() -> void:
	position.x = -size.x
	visibility_changed.connect(_on_visibility_changed)

func show_menu(state: bool = true) -> Tween:
	var new_position: Vector2 = Vector2(0.0, position.y) if state else Vector2(-size.x, position.y)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", new_position, 0.25)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween

func _on_visibility_changed() -> void:
	if visible:
		show_menu()

func _on_back_button_pressed() -> void:
	await show_menu(false).finished
	visible = false
