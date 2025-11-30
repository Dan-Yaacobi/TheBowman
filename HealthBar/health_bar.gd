class_name HealthBar extends TextureProgressBar

var health: int = 0: set = _set_health

func _ready() -> void:
	max_value = PlayerManager.player.get_stamina()
	
func _set_health(new_health) -> void:
	var prev_health = health
	health = min(max_value,new_health)
	value = health
	tooltip_text = str(health) + " / " + str(maxi(max_value,new_health))
	
func init_health(_health: int) -> void:
	health = _health
	max_value = _health
	value = _health
	tooltip_text = str(health) + " / " + str(int(max_value))
