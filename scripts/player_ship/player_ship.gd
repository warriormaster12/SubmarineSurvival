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
@export var damage_curve: Curve = null
@export var damagable_velocity_threshold: float = 5.0
@export var sea_level:Marker3D = null
@export var safe_height: float = 500
@export var death_height: float = 800
@export var drop_of_zones: Array[Node3D] = []
var currentDropOffZone:Vector3 = Vector3.ZERO

## In degrees
@export_range(0.0, 90.0) var camera_look_around_angle: float = 40.0

@export_group("Ship Specs")
@export var mass:float = 4.0

enum engine_states{idle,starting,running,stopping}
var engine_state: engine_states = engine_states.idle
@export var start_player: AudioStreamPlayer 
@export var running_player: AudioStreamPlayer 
@export var stop_player: AudioStreamPlayer 
@export var idle_player: AudioStreamPlayer 
@export var rumble_player: AudioStreamPlayer
@export var collision_player: AudioStreamPlayer

@onready var head: Node3D = $Body/Head
@onready var camera_pivot: Node3D = $Body/Head/CameraPivot
@onready var repair_object_container: Node3D = $RepairObjectContainer

var input_manager: PlayerInputManager = null
var ship_health: ShipHealthSystem = null
var anim_player: AnimationPlayer = null
var direction: Vector3 = Vector3.ZERO
var direction_up: float = 0.0
var turn_direction: float = 0.0
var final_rotation: float = rotation.y

var accel:float = acceleration
var hit:bool = false
var cockpit: bool = true

func _ready() -> void:
	GetNextCoordinates()
	for child in get_children():
		if child is PlayerInputManager:
			input_manager = child
		elif child is ShipHealthSystem:
			ship_health = child
		elif child is AnimationPlayer:
			anim_player = child
	for child in repair_object_container.get_children():
		if child is FixableObject:
			child.on_repair_status_changed.connect(_on_repair_status_changed)
		else:
			push_warning("RepairObjectContainer can only have FixableObjects")
	if input_manager:
		input_manager.on_accelerate.connect(_on_accelerate)
		input_manager.on_mouse_stick_motion.connect(_on_mouse_stick_motion)
		input_manager.on_switching_room.connect(_on_switching_room)
	else: 
		push_warning("no input_manager has been found under " + name + " node")
	
	if !ship_health:
		push_warning("no ship_health has been found under " + name + " node")
	if anim_player:
		anim_player.animation_finished.connect(_on_event_anim_finished)
	else:
		push_warning("no anim_player has been found under " + name + " node")
	
	if !sea_level || !damage_curve:
		push_warning("add sea_level and damage curve in properties")

func _process(delta: float) -> void:
	handle_engine_sounds()

func _physics_process(delta: float) -> void:
	calculate_height_damage()
	if is_on_wall():
		determine_damage_amount()
		print($ImpactShake.trauma)
		collision_player.play()
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
		var damage_amount: float = (velocity.length()/max_speed)
		var damage_percentage: float = clampf(damage_amount * 100, 0.0, 100.0)
		ship_health.set("current_health", ship_health.current_health - damage_percentage)
		velocity = -velocity / mass
		## TODO: don't call add_trauma() directly
		$ImpactShake.add_trauma(damage_amount)
		hit = true
	else: 
		hit = false

func calculate_height_damage() -> void:
	if !sea_level || !damage_curve:
		return
	var current_height: float = sea_level.global_position.y - global_position.y
	if current_height > safe_height:
		var damage_amount: float = damage_curve.sample(current_height/death_height)
		ship_health.set("current_health", ship_health.current_health - damage_amount)
		$PressureShake.add_trauma(damage_amount)
		rumble_player.play()

var stopped: bool = true
var started: bool = true

func handle_engine_sounds() -> void:
	#print("handle_engine ", engine_state, ", stopped ", stopped, ", started ", started)
	if engine_state == engine_states.idle:
		if !stopped:
			if !stop_player.playing:
				start_engine_clip(engine_states.stopping)
			elif stop_player.get_playback_position() >= stop_player.stream.get_length() - 0.1:
				stopped = true
				print("stop")
		elif !idle_player.playing:
			start_engine_clip(engine_states.idle)
	elif engine_state == engine_states.running:
		if !started:
			if !start_player.playing:
				start_engine_clip(engine_states.starting)
			elif start_player.get_playback_position() >= start_player.stream.get_length() - 0.1:
				started = true
		elif !running_player.playing:
			start_engine_clip(engine_states.running)

func start_engine_clip(state: engine_states) -> void:
	if state == engine_states.idle:
		start_player.stop()
		running_player.stop()
		stop_player.stop()
		idle_player.play()
	if state == engine_states.starting:
		start_player.play()
		running_player.stop()
		stop_player.stop()
		idle_player.stop()
	if state == engine_states.running:
		start_player.stop()
		running_player.play()
		stop_player.stop()
		idle_player.stop()
	if state == engine_states.stopping:
		start_player.stop()
		running_player.stop()
		stop_player.play()
		idle_player.stop()

## PlayerInputManager Signals
func _on_accelerate(dir: Vector3) -> void:
	if dir.length():
		if engine_state == engine_states.idle:
			started = false
			stopped = false
		engine_state = engine_states.running
		accel = acceleration
	else: 
		if engine_state == engine_states.running:
			stopped = false
			started = false
		engine_state = engine_states.idle
		accel = deceleration
	direction = Vector3(dir.z, dir.z, dir.z) * -global_basis.z
	direction_up = dir.y
	turn_direction = -dir.x

func _on_mouse_stick_motion(relative_pos: Vector2) -> void: 
	var rad_look: float = deg_to_rad(camera_look_around_angle)
	head.rotate_y(deg_to_rad(relative_pos.x))
	head.rotation.y = clamp(head.rotation.y, -rad_look, rad_look)
	camera_pivot.rotate_x(deg_to_rad(relative_pos.y))
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -rad_look, rad_look)

func _on_switching_room() -> void:
	if anim_player.is_playing():
		return
	input_manager.enable_movement = false
	input_manager.enable_mouse_stick_motion = false
	var camera_tween: Tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera_pivot, "rotation", Vector3.ZERO, 0.2)
	camera_tween.tween_property(head, "rotation", Vector3.ZERO, 0.2)
	camera_tween.set_trans(Tween.TRANS_LINEAR)
	await camera_tween.finished
	if cockpit:
		anim_player.play("EngineRoom")
		cockpit = false
	else: 
		anim_player.play_backwards("EngineRoom")
		cockpit = true
## ~PlayerInputManager Signals

## EventAnimPlayer Signals
func _on_event_anim_finished(_anim_name: StringName) -> void:
	if !cockpit:
		input_manager.enable_mouse_stick_motion = true
	else: 
		input_manager.enable_mouse_stick_motion = true
		input_manager.enable_movement = true

## ~EventAnimPlayer Signals

## FixableObject Signals
func _on_repair_status_changed(node_name: String, status: String) -> void:
	match node_name:
		"Engine":
			if status == "functional":
				max_speed = 5.0
			elif status == "critical":
				max_speed = 0.0
			else:
				max_speed = 10.0
		"WaterPump":
			if status == "functional":
				pass
## ~FixableObject Signals


# objectives
func GetNextCoordinates() -> void:
	if drop_of_zones.size() == 0:
		$"PlayerUI/2DHUD/AnimationPlayer".play("fadeOut")
		await $"PlayerUI/2DHUD/AnimationPlayer".animation_finished
		LoadingScreen.change_scene("res://levels/main_menu.tscn")
		return
	currentDropOffZone = drop_of_zones[0].global_position
	drop_of_zones.pop_at(0)
