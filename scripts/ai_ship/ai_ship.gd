extends StaticBody3D

@export var speed: float = 10.0

var path_follow: PathFollow3D = null

var engine_affect_trigger: Area3D = null

var player: PlayerShip = null
var player_original_speed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent() is PathFollow3D:
		path_follow = get_parent()
	else: 
		push_warning(name + " " + "should be under a PathFollow3D node")
	
	for child in get_children():
		if child is Area3D:
			engine_affect_trigger = child
	if engine_affect_trigger:
		engine_affect_trigger.body_entered.connect(_body_entered)
		engine_affect_trigger.body_exited.connect(_body_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if path_follow:
		path_follow.progress += speed * delta
	if player:
		player.direction += -global_basis.z
		player.direction.normalized()
		player.max_speed += speed

## EngineAffectTrigger Signals
func _body_entered(body: Node3D) -> void:
	if body is PlayerShip:
		player = body
		player_original_speed = player.max_speed

func _body_exited(body: Node3D) -> void:
	if body is PlayerShip:
		player.max_speed = player_original_speed
		player = null
## ~EngineAffectTrigger Signals
