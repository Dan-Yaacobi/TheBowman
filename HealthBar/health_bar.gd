class_name HealthBar extends TextureProgressBar

var health: int = 0: set = _set_health

func _set_health(new_health) -> void:
	var prev_health = health
	health = min(max_value,new_health)
	value = health


func init_health(_health: int) -> void:
	health = _health
	max_value = _health
	value = _health
	
