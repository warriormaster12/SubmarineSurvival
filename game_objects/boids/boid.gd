extends CharacterBody3D

var limits_x : Vector2 = Vector2(-80, 80) 
var limits_z : Vector2 = Vector2(-80, 80)
var limits_y : Vector2 = Vector2(3, 80)

var speeeeed : float = 800
var vel : Vector3
var turn_direction : float = 0.0
var direction: Vector3 = Vector3.ZERO

var flockHeading : Vector3
var flockCentre : Vector3
var avoidanceHeading : Vector3
var numFlockmates : int

var numBoids : int
var viewRadius : float = 100
var avoidRadius : float = 80

var _position : Vector3
var separationHeading : Vector3


func _ready() -> void:
	direction = global_transform.basis.z
	get_parent().boids.append(self)


func _physics_process(delta: float) -> void:
	return
	velocity = Vector3(get_global_transform().basis.z.normalized() * delta * speeeeed)
	var target_vector : Vector3 = global_position.direction_to(-separationHeading)
	var target_basis : Basis = Basis.looking_at(-separationHeading)
	basis = basis.slerp(target_basis, 0.5)
	
	move_and_slide()
	#AvoidOthers()
	CheckForBounds()


func AvoidOthers() -> void:
	var parent : Node = get_parent()
	if (numBoids == 0):
		numBoids = parent.boids.size()
		
	for indexB in numBoids:
		if (parent.boids[indexB] == self):
			continue
		
		var boidB : Object = parent.boids[indexB];
		var offset : Vector3 = boidB.transform.origin - transform.origin
		var sqrDst : float = offset.x * offset.x + offset.y * offset.y + offset.z * offset.z
		if (sqrDst < viewRadius * viewRadius):
			numFlockmates += 1
			flockHeading += boidB.direction
			flockCentre += boidB._position
			if (sqrDst < avoidRadius * avoidRadius):
				separationHeading -= offset / sqrDst




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
	
