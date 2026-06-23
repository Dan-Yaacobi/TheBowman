class_name DeathScreen extends Control

func _ready() -> void:
	visible = false
	EventBus.player_died.connect(death_screen)

func death_screen() -> void:
	modulate.a = 0.0
	visible = true
	get_tree().paused = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
func _on_button_pressed() -> void:
	get_tree().paused = false
	visible = false
