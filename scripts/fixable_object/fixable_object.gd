extends StaticBody3D
class_name FixableObject

@export_range(0.0, 1.0) var repair_rate: float = 0.25
@export var repair_duration: float = 2.0
@export var health_system: ShipHealthSystem = null
## Don't add new key/value pair from the Inspector
@export var repair_conditions: Dictionary = {
	"critical": 0.15,
	"functional": 0.4, 
	"good": 0.7,
}
var mesh_instance: MeshInstance3D = null
var progress_bar_mesh: MeshInstance3D = null
var material: ShaderMaterial = null
var health: float = 1.0
var current_status: String = "good"
var repairing: bool = false
var can_repair: bool = false
var timer: float = 0.0

signal on_repair_status_changed(node_name: String, status: String)

func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D && child.name != "ProgressBar":
			mesh_instance = child
		elif child is MeshInstance3D && child.name == "ProgressBar":
			progress_bar_mesh = child
	
	if mesh_instance:
		material = mesh_instance.mesh.surface_get_material(0)
	else: 
		push_warning("no mesh instance found to display a fixable object. Add one as a child")
	if !progress_bar_mesh:
		push_warning('no "ProgressBar" named mesh instance has been found. Add one as a child')
	else:
		progress_bar_mesh.visible = false
	if !health_system:
		push_warning("no Health System assigned, won't do any repairs")
	else:
		health_system.on_health_changed.connect(_on_health_changed)

func _process(delta: float) -> void:
	can_repair = true if current_status != "good" else false
	if repairing && can_repair:
		timer += delta
		if timer < repair_duration:
			health += repair_rate
			health = clampf(health, 0.0, 1.0)

		%ProgressBarUI.value = (timer/repair_duration) * 100

func set_hover_state(state: bool)->void:
	if material:
		material.set_shader_parameter("FersnelEnabled", state)

func repair_object(state: bool)->void:
	repairing = state
	if progress_bar_mesh:
		progress_bar_mesh.visible = state && can_repair
	if !state:
		%ProgressBarUI.value = 0.0
		timer = 0.0

## HealthSystem Signals
func _on_health_changed(value: float) -> void:
	health = value/health_system.health
	var temp_status:String = current_status
	for val: float in repair_conditions.values():
		if health < val:
			temp_status = repair_conditions.find_key(val)
			break
	if current_status != temp_status:
		current_status = temp_status
		on_repair_status_changed.emit(name, current_status)

## ~HealthSystem Signals
