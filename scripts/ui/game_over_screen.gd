extends Control

@export var wait_before_fading_in: float = 0.25

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var explosion_player: AudioStreamPlayer = $ExplosionPlayer
@onready var game_over_player: AudioStreamPlayer = $GameOverPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer.visible = false


func play_game_over() -> void:
	explosion_player.play()
	await explosion_player.finished
	game_over_player.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	anim_player.play("FadeIn")


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.


func _on_restart_button_pressed() -> void:
	LoadingScreen.restart_current_scene()
