extends Node
class_name PlayerInputManager # exposes this as its own node when in the "create node" menu

@export_group("Settings")
@export var sensitivity: float = 0.3
@export var enable_movement: bool = true
@export var enable_mouse_stick_motion: bool = true

signal on_accelerate(direction: Vector3)
signal on_mouse_stick_motion(realitve_pos: Vector2)
signal on_switching_room

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_mouse_cursor") && OS.has_feature("editor"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseMotion && enable_mouse_stick_motion:
		on_mouse_stick_motion.emit(Vector2(-event.relative.x * sensitivity, -event.relative.y * sensitivity))
	if event.is_action_pressed("switch_rooms"):
		on_switching_room.emit()
	var accel_dir: Vector3 = Vector3(
		Input.get_axis("turn_l","turn_r"),
		Input.get_axis("move_d", "move_u"),
		Input.get_axis("move_b", "move_f") 
	) if enable_movement else Vector3.ZERO
	on_accelerate.emit(accel_dir)

