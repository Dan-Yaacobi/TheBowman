class_name StartMenu extends Control

func _on_button_pressed() -> void:
	get_tree().paused = true

	await SceneTransition.fade_out()
	
	get_tree().change_scene_to_file("res://MainGame/Game.tscn")
		
	await SceneTransition.fade_in()
	
	get_tree().paused = false
	
	await get_tree().process_frame
