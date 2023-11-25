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


var thread : Thread
var semaphore : Semaphore
var mutex : Mutex
var exit := false

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
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	thread = Thread.new()
	thread.start(_thread_boid_calculations)
	
	# using the rendering device to handle the compute commands
	rd = RenderingServer.create_local_rendering_device()
	
	# create shader and pipeline
	var shader_file := load("res://game_objects/boids/boids_compute.glsl")
	var shader_spirv : RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader_file)
	
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
	
	semaphore.post()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _thread_boid_calculations() -> void:
	while true:
		semaphore.wait()
		mutex.lock()
		var should_exit := exit
		mutex.unlock()
		
		if should_exit:
			break
		# ~ R E A L   S T U F F ~   H A P P E N I N G   H E R E   O M G
		mutex.lock()
		# create storage buffer
		var input := []
		for i in numBoids:
			var arr := ([boidData[i].position.x, boidData[i].position.y, boidData[i].position.z, boidData[i].direction.x, boidData[i].direction.y, boidData[i].direction.z, numBoids,  0,0,0,  0,0,0,  0,0,0,  0])
			input.append_array(arr)
		var input_bytes := PackedFloat32Array(input).to_byte_array()
		#print("allVariablesList: ",input,",  PEEEEEEEEEEE BEEEEEEEEEEE AAAAAAAAAAAAA: ",pba)
		storage_buffer = rd.storage_buffer_create(numBoids * 17 * 4, input_bytes)
		mutex.unlock()
		
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
		rd.compute_list_dispatch(compute_list, 2, 1, 1)
		rd.compute_list_end()
		
		rd.submit()
		rd.sync()
		
		var byte_data := rd.buffer_get_data(storage_buffer)
		var output := byte_data.to_float32_array()
		
		mutex.lock()

		
		#for i in boidData.size():
		#	boids[i].position = output[i].position
		#	boids[i].direction = boidData[i].direction
		#	boids[i].flockHeading = boidData[i].flockHeading
		#	boids[i].flockCentre = boidData[i].flockCentre
		#	boids[i].numFlockmates = boidData[i].numFlockmates
		var pb := PackedByteArray()
		rd.buffer_update(storage_buffer, 0, pb.size(), pb)
		
		print("O  U  T  P  U  T  : ", output)

func _exit_tree() -> void:
	mutex.lock()
	exit = true
	mutex.unlock()
	
	semaphore.post()
	thread.wait_to_finish()
	




class BoidData:
	var position : Vector3
	var direction : Vector3
	var flockHeading : Vector3
	var flockCentre : Vector3
	var avoidanceHeading : Vector3
	var numFlockmates : int
