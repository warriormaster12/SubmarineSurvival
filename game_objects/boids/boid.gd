extends CharacterBody3D

var limits_x : Vector2 = Vector2(-50, 50) 
var limits_z : Vector2 = Vector2(-50, 50)
var limits_y : Vector2 = Vector2(-10, 50)

# boid settings
var minSpeed : float = 9
var maxSpeed : float = 15
var maxSteerForce : float = 10
var collisionAvoidDistance : float = 5
var avoidCollisionWeight : float = 5
var alignWeight : float = 0#2
var cohesionWeight : float = 0#0.8
var separationWeight : float = 0#1
var vapinanPaino : float = 0.1


var vel : Vector3
var turn_direction : float = 0.0
var direction: Vector3 = Vector3.ZERO
var flockHeading : Vector3
var flockCentre : Vector3
var avoidanceHeading : Vector3
var numFlockmates : int
var numBoids : int
var _position : Vector3
var separationHeading : Vector3
var parent : Node


func _ready() -> void:
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, true)
	parent = get_parent()
	direction = global_transform.basis.z
	velocity = direction * minSpeed
	parent.boids.append(self)


func UpdateBoid() -> void:
	var acceleration := Vector3.ZERO
	
	if (numFlockmates != 0):
		flockCentre /= numFlockmates
		
		var offsetToFlockmatesCentre := (flockCentre - position)
		
		var alignmentForce := SteerTowards (flockHeading) * alignWeight;
		var cohesionForce := SteerTowards (offsetToFlockmatesCentre) * cohesionWeight;
		var seperationForce := SteerTowards (avoidanceHeading) * separationWeight;
		
		acceleration += alignmentForce
		acceleration += cohesionForce
		acceleration += seperationForce
	
	if IsHeadingForCollision():
		var collisionAvoidDir := ObstacleRays()
		var collisionAvoidForce := SteerTowards(collisionAvoidDir) * avoidCollisionWeight
		acceleration += collisionAvoidForce
	
	velocity += acceleration * get_physics_process_delta_time()
	var speed : float = clamp(velocity.length(), minSpeed, maxSpeed)
	var dir : Vector3 = velocity / speed
	velocity = (dir * speed).clamp(dir * minSpeed, dir * maxSpeed)
	
	look_at(lerp(_position - transform.basis.z, _position - dir, vapinanPaino))
	#Arrow.transform.interpolate_with(new_transform, speed * delta)
	move_and_slide()
	CheckForBounds()


func IsHeadingForCollision() -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position - transform.basis.z * collisionAvoidDistance, collision_mask, [self])
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return false
	else:
		#print("me: ",self.name,", other: ", result.collider.name)
		return true


func ObstacleRays() -> Vector3:
	var rayDirections : Array = parent.rayDirections
	for i in rayDirections.size():
		var dir : Vector3 = transform.basis.inverse() * rayDirections[i]
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(global_position, global_position + dir * collisionAvoidDistance, collision_mask, [self])
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			return dir
	
	return -transform.basis.z


func SteerTowards(vector : Vector3) -> Vector3:
	var v : Vector3 = vector.normalized() * maxSpeed - velocity
	return v.limit_length(maxSteerForce)


func CheckForBounds() -> void:
	if (transform.origin.x < limits_x.x):
		transform.origin.x = limits_x.y
	elif (transform.origin.x > limits_x.y):
		transform.origin.x = limits_x.x
		
	if (transform.origin.z < limits_z.x):
		transform.origin.z = limits_z.y
	elif (transform.origin.z > limits_z.y):
		transform.origin.z = limits_z.x
		
	if (transform.origin.y < limits_y.x):
		transform.origin.y = limits_y.y
	elif (transform.origin.y > limits_y.y):
		transform.origin.y = limits_y.x
