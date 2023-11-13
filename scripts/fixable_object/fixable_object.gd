extends StaticBody3D
class_name FixableObject

@export_range(0.0, 1.0) var repair_degradation_rate: float = 0.05
## In seconds
@export var repair_duration: float = 50.0
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

@onready var new_health: float = health - repair_degradation_rate

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


func set_hover_state(state: bool)->void:
	if material:
		material.set_shader_parameter("FersnelEnabled", state)

func repair_object(state: bool)->void:
	repairing = state && health < new_health
	if repairing:
		var amount_to_add:float = 1/repair_duration
		health += amount_to_add
		health = clampf(health, 0.0, new_health)
		%ProgressBarUI.value = health * 100
		progress_bar_mesh.visible = true
		health_system.set("current_health", health_system.current_health + health * 100)
		if health == new_health:
			repairing = false
			new_health -= repair_degradation_rate
		await get_tree().create_timer(amount_to_add).timeout
	else: 
		progress_bar_mesh.visible = false

## HealthSystem Signals
func _on_health_changed(value: float, depleting: bool) -> void:
	if !repairing && depleting:
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
