extends MeshInstance3D

@export var repair_object_container: Node3D = null
@export var root_control: Control = null

var fixable_labels: Array[Label] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !repair_object_container || !root_control:
		return
	for child in repair_object_container.get_children():
		if child is FixableObject:
			var label := Label.new()
			label.name = child.name + "Label"
			label.text = child.name + ": " + str(child.health * 100) + "%"
			label.add_theme_font_size_override("font_size", 22)
			fixable_labels.push_back(label)
			root_control.add_child(label)
			child.on_health_changed.connect(_on_health_changed)
		else: 
			push_warning(child.name + " is not a fixable object")


func _on_health_changed(node_name: String, health:float) -> void:
	for label in fixable_labels:
		if label.name == node_name + "Label":
			label.text = node_name + ": " + str(round(health * 100)) + "%"
			break
