extends CharacterBody3D
class_name PlayerShip # exposes this as its own node when in the "create node" menu

@export_group("Movement")
@export var max_speed: float = 10.0
@export var acceleration: float = 5.0
@export var deceleration: float = 2.0
## In degrees
@export var turn_threshold: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var input_manager: PlayerInputManager = null
var direction: Vector3 = Vector3.ZERO
var direction_up: float = 0.0

var accel:float = acceleration


func _ready() -> void:
	for child in get_children():
		if child is PlayerInputManager:
			input_manager = child
			break
	if input_manager:
		input_manager.on_accelerate.connect(_on_accelerate)
		input_manager.on_mouse_stick_motion.connect(_on_mouse_stick_motion)
	else: 
		push_warning("no input_manager has been found under " + name)

func _process(_delta: float) -> void:
	if direction.length() > 0 || abs(direction_up) > 0:
		accel = acceleration
	else: 
		accel = deceleration
func _physics_process(delta: float) -> void:
	var ship_rot:float = global_basis.z.signed_angle_to(head.global_basis.z, Vector3.UP)
	if abs(ship_rot) >= deg_to_rad(turn_threshold):
		rotate_y(ship_rot * delta * 1.2)
	velocity.y = move_toward(velocity.y, (direction_up + direction.y) * max_speed, delta * accel)
	velocity.z = move_toward(velocity.z, direction.z * max_speed, delta * accel)
	velocity.x = move_toward(velocity.x, direction.x * max_speed, delta * accel)
	move_and_slide()

## PlayerInputManager Signals
func _on_accelerate(direction: Vector2) -> void:
	self.direction = Vector3(direction.x, direction.x, direction.x) * -camera.global_basis.z
	self.direction_up = direction.y

func _on_mouse_stick_motion(relative_pos: Vector2) -> void: 
	head.rotate_y(deg_to_rad(relative_pos.x))
	head.rotation.y = clamp(head.rotation.y, deg_to_rad(-15), deg_to_rad(15))
	camera.rotate_x(deg_to_rad(relative_pos.y))
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-15), deg_to_rad(15))
## ~PlayerInputManager Signals
