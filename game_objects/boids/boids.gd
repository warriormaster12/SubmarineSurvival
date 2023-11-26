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

var calculating : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# using the rendering device to handle the compute commands
	rd = RenderingServer.get_rendering_device()
	# create shader and pipeline
	var shader_file := load("res://game_objects/boids/boids_compute.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	calculating = true
	StartCalculations()


func _process(delta: float) -> void:
	if calculating:
		return
	
	calculating = true
	StartCalculations()


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
		boidData[i].flockHeading = Vector3.ZERO
		boidData[i].flockCentre = Vector3.ZERO
		boidData[i].avoidanceHeading = Vector3.ZERO
		boidData[i].numFlockmates = 0
		
	boid_calculations()


func boid_calculations() -> void:
	# create storage buffer
	var input := []
	for i in numBoids:
		var arr := ([boidData[i].position, boidData[i].direction, boidData[i].flockHeading, boidData[i].flockCentre, boidData[i].avoidanceHeading, boidData[i].numFlockmates])
		input.append(arr)
	
	var boidDataList := PackedByteArray()
	boidDataList.resize(input.size() * 80)
	for i in input.size():
		print("index ",i,":   ",boidData[i].position,"  ",boidData[i].direction,"  ",boidData[i].flockHeading,"  ", boidData[i].flockCentre, "  ", boidData[i].avoidanceHeading,"  ", boidData[i].numFlockmates)
		boidDataList.encode_float(i * 80, boidData[i].position.x)
		boidDataList.encode_float(i * 80 + 5, boidData[i].position.y)
		boidDataList.encode_float(i * 80 + 10, boidData[i].position.z)
		boidDataList.encode_float(i * 80 + 15, boidData[i].direction.x)
		boidDataList.encode_float(i * 80 + 20, boidData[i].direction.y)
		boidDataList.encode_float(i * 80 + 25, boidData[i].direction.z)
		boidDataList.encode_float(i * 80 + 30, boidData[i].flockHeading.x)
		boidDataList.encode_float(i * 80 + 35, boidData[i].flockHeading.y)
		boidDataList.encode_float(i * 80 + 40, boidData[i].flockHeading.z)
		boidDataList.encode_float(i * 80 + 45, boidData[i].flockCentre.x)
		boidDataList.encode_float(i * 80 + 50, boidData[i].flockCentre.y)
		boidDataList.encode_float(i * 80 + 55, boidData[i].flockCentre.z)
		boidDataList.encode_float(i * 80 + 60, boidData[i].avoidanceHeading.x)
		boidDataList.encode_float(i * 80 + 65, boidData[i].avoidanceHeading.y)
		boidDataList.encode_float(i * 80 + 70, boidData[i].avoidanceHeading.z)
		boidDataList.encode_s8(i * 80 + 75, boidData[i].numFlockmates)
	
	if (!storage_buffer.is_valid()):
		storage_buffer = rd.storage_buffer_create(boidDataList.size(), boidDataList)	
	else:
		rd.buffer_update(storage_buffer, 0, boidDataList.size(), boidDataList)
	
	# create uniform set using the storage buffer
	var u := RDUniform.new()
	u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u.binding = 0
	u.add_id(storage_buffer)
	uniform_set = rd.uniform_set_create([u], shader, 0)
	
	#koita riittääkö tän alla olevan paskan updateeminen sen sijaan, että inputtaa
	#joka kerta boidien datat eka.
	# vvvvvvvvvvvvv
	
	# start compute
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 48, 1, 1)
	rd.compute_list_end()
	
	#rd.submit()
	#rd.sync()
	#  ^^^^^^^^^^^^^
	
	
	var byte_data := rd.buffer_get_data(storage_buffer)
	#var outputList : Array[BoidData] = []
	
	#rd.buffer_update(storage_buffer, 0, boidDataList.size(), boidDataList)
	
	for i in int(byte_data.size() / 80):
		#var boidd : BoidData = BoidData.new()
		boids[i]._position = Vector3(byte_data.decode_float(i * 80), byte_data.decode_float(i * 80 + 5), byte_data.decode_float(i * 80 + 10))
		boids[i].direction = Vector3(byte_data.decode_float(i * 80 + 15), byte_data.decode_float(i * 80 + 20), byte_data.decode_float(i * 80 + 25))
		boids[i].flockHeading = Vector3(byte_data.decode_float(i * 80 + 30), byte_data.decode_float(i * 80 + 35), byte_data.decode_float(i * 80 + 40))
		boids[i].flockCentre = Vector3(byte_data.decode_float(i * 80 + 45), byte_data.decode_float(i * 80 + 50), byte_data.decode_float(i * 80 + 55))
		boids[i].avoidanceHeading = Vector3(byte_data.decode_float(i * 80 + 60), byte_data.decode_float(i * 80 + 65), byte_data.decode_float(i * 80 + 70))
		boids[i].numFlockmates = byte_data.decode_s8(i * 80 + 75)
		boids[i].UpdateBoid()
		#print("boid",i,":  DATA 1: ",byte_data.decode_float(i * 64)," DATA 2: ",byte_data.decode_float(i * 64 +4)," DATA 3: ",byte_data.decode_float(i * 64 +8)," DATA 4: ",byte_data.decode_float(i * 64 +12),"DATA 5: ",byte_data.decode_float(i * 64 +16)," DATA 6: ",byte_data.decode_float(i * 64 +20)," DATA 7: ",byte_data.decode_float(i * 64 +24)," DATA 8: ",byte_data.decode_float(i * 64 +28)," DATA 9: ",byte_data.decode_float(i * 64 +32)," DATA 10: ",byte_data.decode_float(i * 64 +36)," DATA 11: ",byte_data.decode_float(i * 64 +40)," DATA 12: ",byte_data.decode_float(i * 64 +44)," DATA 13: ",byte_data.decode_float(i * 64 +48)," DATA 14: ",byte_data.decode_float(i * 64 +52)," DATA 15: ",byte_data.decode_float(i * 64 +56)," DATA 16: ",byte_data.decode_float(i * 64 +60))
		
		#boidd.position = Vector3(byte_data.decode_float(i * 64), byte_data.decode_float(i * 64 + 4), byte_data.decode_float(i * 64 + 8))
		#boidd.direction = Vector3(byte_data.decode_float(i * 64 + 12), byte_data.decode_float(i * 64 + 16), byte_data.decode_float(i * 64 + 20))
		#boidd.flockHeading = Vector3(byte_data.decode_float(i * 64 + 24), byte_data.decode_float(i * 64 + 28), byte_data.decode_float(i * 64 + 32))
		#boidd.flockCentre = Vector3(byte_data.decode_float(i * 64 + 36), byte_data.decode_float(i * 64 + 40), byte_data.decode_float(i * 64 + 44))
		#boidd.avoidanceHeading = Vector3(byte_data.decode_float(i * 64 + 48), byte_data.decode_float(i * 64 + 52), byte_data.decode_float(i * 64 + 56))
		#boidd.numFlockmates = byte_data.decode_s32(i * 64 + 60)
		#outputList.append(boidd)
		#print(boidd.position," ",boidd.direction," ",boidd.flockHeading," ",boidd.flockCentre," ",boidd.avoidanceHeading," ",boidd.numFlockmates)
	
	calculating = false


class BoidData:
	var position : Vector3 = Vector3.ZERO
	var direction : Vector3 = Vector3.ZERO
	var flockHeading : Vector3 = Vector3.ZERO
	var flockCentre : Vector3 = Vector3.ZERO
	var avoidanceHeading : Vector3 = Vector3.ZERO
	var numFlockmates : int = 0
