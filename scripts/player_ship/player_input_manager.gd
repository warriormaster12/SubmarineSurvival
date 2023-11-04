extends Node
class_name PlayerInputManager # exposes this as its own node when in the "create node" menu

@export_group("Settings")
@export var sensitivity: float = 0.3

signal on_accelerate(direction: Vector2)
signal on_mouse_stick_motion(realitve_pos: Vector2)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_mouse_cursor") && OS.has_feature("editor"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion:
		on_mouse_stick_motion.emit(Vector2(-event.relative.x * sensitivity, -event.relative.y * sensitivity))
	var accel_dir: Vector2 = Input.get_vector("move_b","move_f","move_d","move_u")
	on_accelerate.emit(accel_dir)

