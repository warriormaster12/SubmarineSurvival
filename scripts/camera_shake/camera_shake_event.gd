extends Node
class_name CameraShakeEvent

@export_group("Settings")
## Shake intensity will decrease by reduction rate every second
@export var trauma_reduction_rate: float = 1.0
@export var max_angle: Vector3 = Vector3(10, 10, 5)
@export var noise_texture: FastNoiseLite = null
@export var noise_speed: float = 50.0

var trauma: float = 0.0
var init_rot: Vector3 = Vector3.ZERO
var time: float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)
	var current_camera: Camera3D = get_viewport().get_camera_3d()
	current_camera.rotation_degrees = Vector3(
		init_rot.x + max_angle.x * get_shake_intensity() * get_noise_from_seed(0),
		init_rot.y + max_angle.x * get_shake_intensity() * get_noise_from_seed(1),
		init_rot.z + max_angle.x * get_shake_intensity() * get_noise_from_seed(2)
	)

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(noise_seed: int) -> float:
	if noise_texture:
		noise_texture.seed = noise_seed
		return noise_texture.get_noise_1d(time * noise_speed)
	return 0.0
