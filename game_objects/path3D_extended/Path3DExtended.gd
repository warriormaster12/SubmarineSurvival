extends Path3D
class_name Path3DExtended

@export_file("*.tscn", "*.scn") var object_to_spawn: String = ""

## If trigger is not specified then path following object is spawned at the start of the level
@export var area_trigger: Area3D = null
@export var triggerer: Node3D = null
@export_group("PathFolow3D")
## If disabled then this node is going to be deleted after going a path once
@export var loop: bool = false
@export var cubic_interp: bool = true
@export var rotation_mode: PathFollow3D.RotationMode = PathFollow3D.RotationMode.ROTATION_XYZ
@export var tilt_enabled: bool = true

var path_follow: PathFollow3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if area_trigger:
		area_trigger.body_entered.connect(_on_body_entered, CONNECT_ONE_SHOT)
	else: 
		spawn_object()

func spawn_object() -> void:
	if !object_to_spawn.is_empty():
		path_follow = PathFollow3D.new()
		path_follow.name = "AIShipPathFollow3D"
		path_follow.cubic_interp = cubic_interp
		path_follow.loop = loop
		path_follow.rotation_mode = rotation_mode
		path_follow.use_model_front = false
		path_follow.tilt_enabled = tilt_enabled
		add_child(path_follow)
		var object_packed:PackedScene = load(object_to_spawn)
		var object_inst: Node = object_packed.instantiate()
		if !object_inst is Node3D:
			object_inst.queue_free()
			push_warning(object_to_spawn + " doesn't inherit type Node3D. Can't follow path")
			return
		path_follow.add_child(object_inst)

func _process(_delta: float) -> void:
	if path_follow:
		if path_follow.progress_ratio >= 1.0 && !loop:
			queue_free()
			print("path loppui")
func _on_body_entered(body: Node3D) -> void:
	if triggerer != null && body == triggerer:
		spawn_object()
		area_trigger.queue_free()
