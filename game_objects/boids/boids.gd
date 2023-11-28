extends Node

#BoidSettings
var minSpeed : float = 2
var maxSpeed : float = 5
var perceptionRadius : float = 2.5
var avoidanceRadius : float = 1
var maxSteerForce : float = 100
var alignWeight : float = 0.6
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
	CalculateRayDirections()
	
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
		boidData[i].position = Vector4(boids[i].position.x, boids[i].position.y, boids[i].position.z, 0)
		boidData[i].direction = Vector4(boids[i].direction.x, boids[i].direction.y, boids[i].direction.z, 0)
		boidData[i].flockHeading = Vector4.ZERO
		boidData[i].flockCentre = Vector4.ZERO
		boidData[i].avoidanceHeadingAndFlockmates = Vector4.ZERO
		
	boid_calculations()


func boid_calculations() -> void:
	# create storage buffer
	var input := []
	var boidDataList := PackedByteArray()
	boidDataList.resize(100 * 80)
	for i in range(0, 100):
		boidDataList.encode_float(i * 80, boidData[i].position.x)
		boidDataList.encode_float(i * 80 + 4, boidData[i].position.y)
		boidDataList.encode_float(i * 80 + 8, boidData[i].position.z)
		boidDataList.encode_float(i * 80 + 16, boidData[i].direction.x)
		boidDataList.encode_float(i * 80 + 20, boidData[i].direction.y)
		boidDataList.encode_float(i * 80 + 24, boidData[i].direction.z)
		
	if (!storage_buffer.is_valid()):
		storage_buffer = rd.storage_buffer_create(boidDataList.size(), boidDataList)
	else:
		rd.buffer_update(storage_buffer, 0, boidDataList.size(), boidDataList)
	
	# create uniform set using the storage buffer
	if !uniform_set.is_valid():
		var u := RDUniform.new()
		u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		u.binding = 0
		u.add_id(storage_buffer)
		uniform_set = rd.uniform_set_create([u], shader, 0)
	
	# start compute
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 100, 1, 1)
	rd.compute_list_end()
	
	var byte_data := rd.buffer_get_data(storage_buffer)
	
	for i in int(byte_data.size() / 80):
		boids[i]._position = Vector3(byte_data.decode_float(i * 80), byte_data.decode_float(i * 80 + 4), byte_data.decode_float(i * 80 + 8))
		boids[i].direction = Vector3(byte_data.decode_float(i * 80 + 16), byte_data.decode_float(i * 80 + 20), byte_data.decode_float(i * 80 + 24))
		boids[i].flockHeading = Vector3(byte_data.decode_float(i * 80 + 32), byte_data.decode_float(i * 80 + 36), byte_data.decode_float(i * 80 + 40))
		boids[i].flockCentre = Vector3(byte_data.decode_float(i * 80 + 48), byte_data.decode_float(i * 80 + 52), byte_data.decode_float(i * 80 + 56))
		boids[i].avoidanceHeading = Vector3(byte_data.decode_float(i * 80 + 64), byte_data.decode_float(i * 80 + 68), byte_data.decode_float(i * 80 + 72))
		boids[i].numFlockmates = int(byte_data.decode_float(i * 80 + 76))
		#print("BOID ",i,":   pos: ",boids[i]._position,",  dir: ",boids[i].direction,",  flockHeadin: ",boids[i].flockHeading,",  flockCentr: ",boids[i].flockCentre,",  avoidanceHeadn: ",boids[i].avoidanceHeading,",  numFlockmates: ",boids[i].numFlockmates)
		boids[i].UpdateBoid()
	
	calculating = false


class BoidData: 												# index offsets:
	var position : Vector4 = Vector4.ZERO   					# 0  4  8  (12 = unused)
	var direction : Vector4 = Vector4.ZERO  					# 16 20 24 (28 = unused)
	var flockHeading : Vector4 = Vector4.ZERO   				# 32 36 40 (44 = unused)
	var flockCentre : Vector4 = Vector4.ZERO    				# 48 52 56 (60 = unused)
	var avoidanceHeadingAndFlockmates : Vector4 = Vector4.ZERO  # 64 68 72 (76 = flockmates)



#  R A Y S   F O R   O B S T A C L E   A V O I D A N C E :
var rayDirections : Array

var numViewDirections : float = 100
var goldenRatio : float = (1 + sqrt(5)) / 2
var angleIncrement : float = PI * 2 * goldenRatio
func CalculateRayDirections() -> void:
	for i in numViewDirections:
		var t := float(i) / numViewDirections
		var inclination := acos(1 - 2 * t)
		var azimuth := angleIncrement * i
		
		var x := sin(inclination) * cos(azimuth)
		var y := sin(inclination) * sin(azimuth)
		var z := cos(inclination)
		rayDirections.append(Vector3(x,y,z))

