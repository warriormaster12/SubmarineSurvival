extends Camera3D
class_name PlayerCamera

var current_fixable: FixableObject = null

var interacting: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interacting = true
	elif event.is_action_released("interact"):
		interacting = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = project_ray_origin(mouse_pos)
	var to: Vector3 = from + project_ray_normal(mouse_pos) * 100
	
	# enabling layer 3 
	# https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to,  0b0100)
	var result: Dictionary = space_state.intersect_ray(query)
	if !result.is_empty() && result.collider is FixableObject:
		if current_fixable != result.collider:
			current_fixable = result.collider
			current_fixable.set_hover_state(true)
	elif result.is_empty():
		if current_fixable:
			current_fixable.set_hover_state(false)
			current_fixable = null

	if current_fixable:
		current_fixable.repair_object(interacting)
