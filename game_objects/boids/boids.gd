extends Node

#BoidSettings
var minSpeed : float = 2
var maxSpeed : float = 5
var perceptionRadius : float = 2.5
var avoidanceRadius : float = 1
var maxSteerForce : float = 3
var alignWeight : float = 1
var cohesionWeight : float = 1
var separateWeight : float = 1
var targetWeight : float = 1
	#collisions
var boundsRadius : float = 0.27
var avoidCollisionWeight : float = 10
var collisionAvoidDist : float = 5

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var storage_buffer : RID
var uniform_set : RID

#var buffer_uniform
const threadGroupSize : int = 1024
var computeShader : RDShaderFile

var boids : Array = []
var boidData : Array = []
var numBoids : int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# using the rendering device to handle the compute commands
	rd = RenderingServer.create_local_rendering_device()
	# create shader and pipeline
	var shader_file := load("res://game_objects/boids/boids_compute.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	StartCalculations()
	boid_calculations()

func StartCalculations() -> void:
	numBoids = boids.size()
	if (numBoids == 0):
		return
		
	boidData.clear()
	for i in numBoids:
		boidData.append(BoidData.new())
	
	for i in boidData.size():
		boidData[i].position = boids[i].position
		boidData[i].direction = boids[i].direction
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func boid_calculations() -> void:
	# ~ R E A L   S T U F F ~   H A P P E N I N G   H E R E   O M G
	# create storage buffer
	var input := []
	for i in numBoids:
		var arr := ([boidData[i].position, boidData[i].direction, boidData[i].flockHeading, boidData[i].flockCentre, boidData[i].avoidanceHeading, boidData[i].numFlockmates])
		input.append(arr)
	
	var NEWEST_LIST_BYTES := PackedByteArray()
	NEWEST_LIST_BYTES.resize(input.size() * 32)
	for i in input.size():
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].position.x)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].position.y)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].position.z)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].direction.x)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].direction.y)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].direction.z)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockHeading.x)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockHeading.y)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockHeading.z)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockCentre.x)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockCentre.y)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].flockCentre.z)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].avoidanceHeading.x)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].avoidanceHeading.y)
		NEWEST_LIST_BYTES.encode_float(i * 32, boidData[i].avoidanceHeading.z)
		NEWEST_LIST_BYTES.encode_s32(i * 32, boidData[i].numFlockmates)
	
	#var input_bytes := PackedFloat32Array(input).to_byte_array()
	storage_buffer = rd.storage_buffer_create(NEWEST_LIST_BYTES.size(), NEWEST_LIST_BYTES)
	
	
	# create uniform set using the storage buffer
	var u := RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u.binding = 0
	u.add_id(storage_buffer)
	uniform_set = rd.uniform_set_create([u], shader, 0)
	
	# E N D   O F   ~ R E A L   S T U F F ~
	# start compute
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 1, 1, 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	
	var byte_data := rd.buffer_get_data(storage_buffer)
	var output := byte_data.to_float32_array()
	
	#print("O  U  T  P  U  T   NRO-1: ", output)

	
	#for i in boidData.size():
	#	boids[i].position = output[i].position
	#	boids[i].direction = boidData[i].direction
	#	boids[i].flockHeading = boidData[i].flockHeading
	#	boids[i].flockCentre = boidData[i].flockCentre
	#	boids[i].numFlockmates = boidData[i].numFlockmates
	#var pb := PackedByteArray()
	#rd.buffer_update(storage_buffer, 0, pb.size(), pb)
	
	#print("O  U  T  P  U  T  NRO-2: ", output)
	




class BoidData:
	var position : Vector3
	var direction : Vector3
	var flockHeading : Vector3
	var flockCentre : Vector3
	var avoidanceHeading : Vector3
	var numFlockmates : int
