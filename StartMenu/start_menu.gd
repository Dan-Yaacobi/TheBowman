class_name StartMenu extends Control

func _on_start_button_pressed() -> void:
	EventBus.button_click_sound.emit()
	get_tree().paused = true

	await SceneTransition.fade_out()
	
	get_tree().change_scene_to_file("res://MainGame/Game.tscn")
		
	await SceneTransition.fade_in()
	
	get_tree().paused = false
	
	await get_tree().process_frame


func _on_exit_button_pressed() -> void:
	EventBus.button_click_sound.emit()
	get_tree().quit()
