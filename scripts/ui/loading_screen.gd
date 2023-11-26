extends CanvasLayer


var scene_name: String = ""
var progress: Array = []
func _ready() -> void:
	set_process(false)
	visible = false

func change_scene(path: String) -> void:
	if path.length() > 0:
		ResourceLoader.load_threaded_request(path)
		set_process(true)
		visible = true
		scene_name = path

func restart_current_scene() -> void:
	change_scene(get_tree().get_current_scene().scene_file_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var scene_load_status := ResourceLoader.load_threaded_get_status(scene_name, progress)
	$LoadingScreen/LoadingBar.value = floor(progress[0] * 100)
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene := ResourceLoader.load_threaded_get(scene_name)
		get_tree().change_scene_to_packed(new_scene)
		progress.clear()
		scene_name = ""
		set_process(false)
		visible = false
