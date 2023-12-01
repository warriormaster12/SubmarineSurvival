extends Node3D

@export var rotation_speed: float = 5.0
@export var repair_container:Node3D = null
var spotlight: SpotLight3D = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spotlight = get_child(0)
	spotlight.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if spotlight.visible:
		spotlight.rotate_y(-delta * rotation_speed)
	for child in repair_container.get_children():
		if child.current_status == "critical":
			if !$Alarm.is_playing():
				$Alarm.play()
			spotlight.visible = true
		else: 
			spotlight.visible = false
			if $Alarm.is_playing():
				$Alarm.stop()


