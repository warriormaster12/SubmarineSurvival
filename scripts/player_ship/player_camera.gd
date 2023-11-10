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
func _process(_delta: float) -> void:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	
	var from: Vector3 = project_ray_origin(mouse_pos)
	var to: Vector3 = from + project_ray_normal(mouse_pos) * 1000
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		if result.collider is FixableObject && current_fixable != result.collider:
			current_fixable = result.collider
			current_fixable.set_hover_state(true)
	else: 
		if current_fixable:
			current_fixable.set_hover_state(false)
			current_fixable = null
	if current_fixable:
		current_fixable.repair_object(interacting)
