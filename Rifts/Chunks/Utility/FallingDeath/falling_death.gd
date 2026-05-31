extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)
