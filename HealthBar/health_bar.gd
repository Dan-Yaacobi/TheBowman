class_name HealthBar extends TextureProgressBar
@onready var ghost_bar: TextureProgressBar = $"../GhostBar"

var health: int = 0: set = _set_health
var _ghost_tween: Tween

func _set_health(new_health) -> void:
	health = int(min(max_value,new_health))
	value = health
	max_value = max(health,max_value)
	update_tooltip()
	
func init_health(_health: int) -> void:
	max_value = _health
	health = _health
	value = _health
	ghost_bar.max_value = _health
	ghost_bar.value = _health
	
func reduce_health(amount: int) -> void:
	var old_health: float = float(health)
	health -= amount
	_animate_ghost(old_health)

func _animate_ghost(from: float) -> void:
	if _ghost_tween:
		_ghost_tween.kill()
	_ghost_tween = create_tween()
	_ghost_tween.tween_interval(0.2)
	_ghost_tween.tween_method(_set_ghost_value, from, float(health), 0.3)
	
func _set_ghost_value(val: float) -> void:
	ghost_bar.value = val
	
func heal(amount: int) -> void:
	health += amount

func update_tooltip() -> void:
	tooltip_text = str(int(value)) + " / " + str(int(max_value))

func increase_max_hp(_new_value: int) -> void:
	max_value = max(max_value,_new_value)
	ghost_bar.max_value = max_value
	update_tooltip()
