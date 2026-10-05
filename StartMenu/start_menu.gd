class_name StartMenu extends Control

const GAME_SCENE: String = "res://MainGame/Game.tscn"

@onready var start_button: Button = $VBoxContainer/StartButton

func _ready() -> void:
	start_button.text = "Continue" if SaveService.has_save() else "New Game"

func _on_start_button_pressed() -> void:
	EventBus.button_click_sound.emit()
	get_tree().paused = true
	await SceneTransition.fade_out()
	get_tree().change_scene_to_file(GAME_SCENE)
	await SceneTransition.fade_in()
	get_tree().paused = false
	await get_tree().process_frame

func _on_exit_button_pressed() -> void:
	EventBus.button_click_sound.emit()
	get_tree().quit()
