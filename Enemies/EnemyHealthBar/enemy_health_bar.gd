class_name EnemyHealthBar extends TextureProgressBar

@onready var enemy_ghost_bar: TextureProgressBar = $"../EnemyGhostBar"
@onready var enemy_health_bar_container: Control = $".."

var _fade_tween: Tween
var _value_tween: Tween
var _ghost_tween: Tween

func setup(max_hp: int) -> void:
	max_value = max_hp
	value = max_hp
	enemy_ghost_bar.max_value = max_hp
	enemy_ghost_bar.value = max_hp
	enemy_ghost_bar.step = 0.01
	enemy_health_bar_container.modulate.a = 0.0

func show_damage(current_hp: int) -> void:
	_animate_value(current_hp)
	_animate_ghost(current_hp)
	_animate_visibility()

func _animate_value(current_hp: int) -> void:
	if _value_tween:
		_value_tween.kill()
	_value_tween = create_tween()
	_value_tween.tween_property(self, "value", float(current_hp), 0.2)

func _animate_ghost(current_hp: int) -> void:
	if _ghost_tween:
		_ghost_tween.kill()
	_ghost_tween = create_tween()
	_ghost_tween.tween_interval(0.2)
	_ghost_tween.tween_method(_set_ghost_value, enemy_ghost_bar.value, float(current_hp), 0.3)

func _set_ghost_value(val: float) -> void:
	enemy_ghost_bar.value = val

func _animate_visibility() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(enemy_health_bar_container, "modulate:a", 1.0, 0.15)
	_fade_tween.tween_interval(2.0)
	_fade_tween.tween_property(enemy_health_bar_container, "modulate:a", 0.0, 0.5)
