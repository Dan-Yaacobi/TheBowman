class_name HealthBar extends TextureProgressBar

var health: int = 0: set = _set_health
	
func _set_health(new_health) -> void:
	health = int(min(max_value,new_health))
	value = health
	max_value = max(health,max_value)
	update_tooltip()
	
func init_health(_health: int) -> void:
	max_value = _health
	health = _health
	value = _health
	
func reduce_health(amount: int) -> void:
	health -= amount

func heal(amount: int) -> void:
	health += amount

func update_tooltip() -> void:
	tooltip_text = str(int(value)) + " / " + str(int(max_value))

func increase_max_hp(_new_value: int) -> void:
	max_value = max(max_value,_new_value)
	update_tooltip()
