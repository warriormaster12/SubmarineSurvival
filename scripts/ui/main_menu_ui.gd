extends Control

@export_file("*.tscn", "*.scn") var starting_level: String = ""

@export var sub_menus: Array[Control] = []

@onready var foreground: ColorRect = $Foreground
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var buttons: VBoxContainer = $Menu/Buttons
@onready var menu: Control =$Menu


func _ready() -> void:
	for sub_menu in sub_menus:
		sub_menu.visible = false
		sub_menu.visibility_changed.connect(_on_visibility_changed)
	foreground.color.a = 1.0
	buttons.position.x = -buttons.size.x
	anim_player.play("FadeIn")
	await anim_player.animation_finished
	show_buttons()

func show_buttons(state: bool = true) -> Tween:
	var new_position: Vector2 = Vector2(0.0, buttons.position.y) if state else Vector2(-buttons.size.x, buttons.position.y)
	var tween: Tween = create_tween()
	tween.tween_property(buttons, "position", new_position, 0.25)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween

func show_menu(state: bool = true) -> Tween:
	var new_position: Vector2 = Vector2(0.0, menu.position.y) if state else Vector2(-menu.size.x, menu.position.y)
	var tween: Tween = create_tween()
	tween.tween_property(menu, "position", new_position, 0.25)
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_IN_OUT)
	return tween

func _on_start_game_button_pressed() -> void:
	if starting_level.is_empty():
		push_warning("starting_level variable is empty")
		return
	await show_buttons(false).finished
	anim_player.play_backwards("FadeIn")
	await anim_player.animation_finished
	LoadingScreen.change_scene(starting_level)


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_how_to_play_button_pressed() -> void:
	for sub_menu in sub_menus:
		if sub_menu.name == "HowToPlay":
			await show_menu(false).finished
			sub_menu.visible = true
			break


func _on_quit_game_button_pressed() -> void:
	await show_buttons(false).finished
	anim_player.play_backwards("FadeIn")
	await anim_player.animation_finished
	get_tree().quit()
	

func _on_visibility_changed() -> void:
	var sub_menu_visible: bool = false
	for sub_menu in sub_menus:
		if sub_menu.visible:
			sub_menu_visible = true
			break
	if !sub_menu_visible:
		menu.visible = true
		show_menu()
