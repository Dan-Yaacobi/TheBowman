class_name Stunned extends EnemyEffect

const STUNNED_TIMER = preload("res://Enemies/EnemyEffects/Stunned/stunned_timer.tscn")
const STUNNED_EFFECT = preload("res://Enemies/EnemyEffects/Stunned/stunned_effect.tscn")
var duration: float = 3.0

func activate_enemy_effect(_enemy: Enemy) -> void:
	if _enemy != null:
		var stunned_timer: Timer = STUNNED_TIMER.instantiate()
		var stunned_effect: CPUParticles2D = STUNNED_EFFECT.instantiate()
		stunned_timer.wait_time = duration
		_enemy.add_child(stunned_timer)
		_enemy.add_child(stunned_effect)
		_enemy.stunned_timer = stunned_timer
		_enemy.stunned_effect = stunned_effect
		_enemy.stunned()

func set_stun_duration(_duration) -> void:
	duration = _duration
