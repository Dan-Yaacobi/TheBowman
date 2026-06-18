class_name Boss extends Enemy

var boss_health_bar: HealthBar

func handle_health_bar(_dmg: int = 0) -> void:
	boss_health_bar.reduce_health(_dmg)
