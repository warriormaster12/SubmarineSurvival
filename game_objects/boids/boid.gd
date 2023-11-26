extends CharacterBody3D

var limits_x : Vector2 = Vector2(-80, 80) 
var limits_z : Vector2 = Vector2(-80, 80)
var limits_y : Vector2 = Vector2(3, 80)

var speeeeed : float = 800
var minSpeed : float = 2.0
var maxSpeed : float = 5.0
var maxSteerForce : float = 3.0
var vel : Vector3
var turn_direction : float = 0.0
var direction: Vector3 = Vector3.ZERO

var flockHeading : Vector3
var flockCentre : Vector3
var avoidanceHeading : Vector3
var numFlockmates : int

var numBoids : int
var viewRadius : float = 1
var avoidRadius : float = 2.5

var _position : Vector3
var separationHeading : Vector3


func _ready() -> void:
	direction = global_transform.basis.z
	velocity = direction * minSpeed
	get_parent().boids.append(self)


func UpdateBoid() -> void:
	var acceleration := Vector3.ZERO
	
	if (numFlockmates != 0):
		flockCentre /= numFlockmates
		
		var offsetToFlockmatesCentre := (flockCentre - position)
		
		var alignmentForce := SteerTowards (flockHeading) * 1 #settings.alignWeight;
		var cohesionForce := SteerTowards (offsetToFlockmatesCentre) * 1 #settings.cohesionWeight;
		var seperationForce := SteerTowards (avoidanceHeading) * 1 #settings.seperateWeight;
	
		acceleration += alignmentForce
		acceleration += cohesionForce
		acceleration += seperationForce
	
	#if (IsHeadingForCollision ()) {
		#Vector3 collisionAvoidDir = ObstacleRays ();
		#Vector3 collisionAvoidForce = SteerTowards (collisionAvoidDir) * settings.avoidCollisionWeight;
		#acceleration += collisionAvoidForce;
	#}
	velocity += acceleration * get_physics_process_delta_time()
	var v := velocity.length()
	var speed : float = 0
	if v == null:
		speed = minSpeed
	else:
		speed = v
	var dir : Vector3 = velocity / speed
	velocity = dir * speed
	
	look_at(dir)
	move_and_slide()
	
	#cachedTransform.position += velocity * delta
	#cachedTransform.forward = dir;
	#position = cachedTransform.position;
	#forward = dir;
	
	CheckForBounds()


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
