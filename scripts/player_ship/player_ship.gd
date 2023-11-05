extends CharacterBody3D
class_name PlayerShip # exposes this as its own node when in the "create node" menu

@export_group("Movement")
@export var max_speed: float = 10.0
@export var acceleration: float = 5.0
@export var deceleration: float = 2.0
## In degrees
@export_range(0.0, 90.0) var max_turn_angle: float = 25.0
@export var turn_speed: float = 0.9

@export_group("Misc")
@export var damagable_velocity_threshold: float = 5.0
## In degrees
@export var camera_look_around_angle: float = 40.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var input_manager: PlayerInputManager = null
var ship_health: ShipHealthSystem = null
var direction: Vector3 = Vector3.ZERO
var direction_up: float = 0.0
var turn_direction: float = 0.0
var final_rotation: float = rotation.y

var accel:float = acceleration
var hit:bool = false

func _ready() -> void:
	for child in get_children():
		if child is PlayerInputManager:
			input_manager = child
		elif child is ShipHealthSystem:
			ship_health = child

	if input_manager:
		input_manager.on_accelerate.connect(_on_accelerate)
		input_manager.on_mouse_stick_motion.connect(_on_mouse_stick_motion)
	else: 
		push_warning("no input_manager has been found under " + name + " node")
	
	if !ship_health:
		push_warning("no ship_health has been found under " + name + " node")

func _process(_delta: float) -> void:
	if direction.length() > 0:
		accel = acceleration
	else: 
		accel = deceleration
func _physics_process(delta: float) -> void:
	if is_on_wall():
		determine_damage_amount()
	rotate_y(deg_to_rad(max_turn_angle) * turn_direction * turn_speed * delta)
	velocity.y = move_toward(velocity.y, direction_up * max_speed, delta * accel)
	velocity.z = move_toward(velocity.z, direction.z * max_speed, delta * accel)
	velocity.x = move_toward(velocity.x, direction.x * max_speed, delta * accel)
	move_and_slide()

func determine_damage_amount() -> void:
	if !ship_health:
		return
	if velocity.length() >= damagable_velocity_threshold:
		if hit:
			return
		var damage_percentage: float = (velocity.length()/max_speed) * 100
		damage_percentage = clampf(damage_percentage, 0.0, 100.0)
		ship_health.set("current_health", ship_health.current_health - damage_percentage)
		hit = true
	else: 
		hit = false

## PlayerInputManager Signals
func _on_accelerate(dir: Vector3) -> void:
	direction = Vector3(dir.z, dir.z, dir.z) * -global_basis.z
	direction_up = dir.y
	turn_direction = -dir.x

func _on_mouse_stick_motion(relative_pos: Vector2) -> void: 
	head.rotate_y(deg_to_rad(relative_pos.x))
	var rad_look: float = deg_to_rad(camera_look_around_angle)
	head.rotation.y = clamp(head.rotation.y, -rad_look, rad_look)
	camera.rotate_x(deg_to_rad(relative_pos.y))
	camera.rotation.x = clamp(camera.rotation.x, -rad_look, rad_look)
## ~PlayerInputManager Signals
