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
	if _ghost_tween:
		_ghost_tween.kill()
	ghost_bar.value = maxf(ghost_bar.value, float(health))
	
func update_tooltip() -> void:
	tooltip_text = str(int(value)) + " / " + str(int(max_value))

func set_instant(new_health: int, new_max: int) -> void:
	if _ghost_tween:
		_ghost_tween.kill()
		_ghost_tween = null
	max_value = new_max
	health = new_health
	ghost_bar.max_value = new_max
	ghost_bar.value = health
