extends MeshInstance3D

@export var root_control: Control = null

@export var label_resources: Array[LabelResource] = []

var labels: Array[Label] = []

var ship: PlayerShip = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_owner() is PlayerShip:
		ship = get_owner()
	if !root_control:
		return
	for label_resource in label_resources: 
		var label := Label.new()
		label.name = label_resource.label_name
		label.add_theme_font_size_override("font_size", 18)
		root_control.add_child(label)
		labels.push_back(label)

func update_labels() -> void: 
	for i in range(0, label_resources.size()):
		var label_resource: LabelResource = label_resources[i]
		var label: Label = labels[i]
		label.text = label_resource.label_name + ": "
		if label_resource.is_length:
			label.text += str(snappedf(ship.get(label_resource.variable).length(), 0.01))
		else: 
			label.text +=  str(snapped(ship.get(label_resource.variable),Vector3(0.01,0.01,0.01)))

func _process(_delta: float) -> void:
	update_labels()
