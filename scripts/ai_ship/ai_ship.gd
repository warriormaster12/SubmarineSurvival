extends StaticBody3D

@export var speed: float = 10.0

var path_follow: PathFollow3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent() is PathFollow3D:
		path_follow = get_parent()
	else: 
		push_warning(name + " " + "should be under a PathFollow3D node")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if path_follow:
		path_follow.progress += speed * delta
