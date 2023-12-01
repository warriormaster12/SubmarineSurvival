extends CanvasLayer


var player: PlayerShip = null
@export var ui_elements: Array[UIEventResource] = []
@export var deletable_resources: Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_nodes_in_group("player")[0]
	
	if !player:
		push_warning("no player ship found")
		return
	
	for ui in ui_elements:
		var ui_node: Control = get_node(ui.node_path)
		ui_node.visible = ui.visible_on_ready
	
	player.ship_health.on_health_depleted.connect(_on_health_depleted, CONNECT_ONE_SHOT)


func _on_health_depleted() -> void:
	for ui in ui_elements:
		if ui.event_name == "_on_health_depleted":
			var ui_node: Control = get_node(ui.node_path)
			ui_node.visible = true
			if ui_node.has_method(ui.execute_function):
				ui_node.call(ui.execute_function)
	player.queue_free()
	for resource in deletable_resources:
		resource.queue_free()
