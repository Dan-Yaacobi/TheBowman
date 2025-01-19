class_name PoisonEffect extends EnemyEffect

@export var tick_intervals: float = 0.2
@export var damage: int = 2

const POISONED_EFFECT = preload("res://Enemies/EnemyEffects/Poisoned/poisoned_effect.tscn")
const POISONED_TIMER = preload("res://Enemies/EnemyEffects/Poisoned/poisoned_timer.tscn")

func activate_enemy_effect(_enemy: Enemy) -> void:
	if _enemy != null:
		var poisoned_effect: CPUParticles2D = POISONED_EFFECT.instantiate()
		var poisoned_timer: Timer = POISONED_TIMER.instantiate()
		poisoned_timer.wait_time = tick_intervals
		poisoned_effect.emitting = true
		_enemy.add_child(poisoned_effect)
		_enemy.add_child(poisoned_timer)
		_enemy.poisoned_timer = poisoned_timer
		_enemy.poisoned(damage)
		
