class_name WizardDeadState extends EnemyState

@export var dead_animation: String = "Dead"

var _elapsed: float = 0.0
var _length: float = 0.0

func Enter() -> void:
	_elapsed = 0.0
	var wizard: WizardBoss = enemy as WizardBoss
	wizard.lock_facing = true
	wizard.set_targetable(false)
	wizard.update_animation(dead_animation)
	_length = 0.0
	if wizard.animation_player and wizard.animation_player.has_animation(dead_animation):
		_length = wizard.animation_player.get_animation(dead_animation).length

func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	if _elapsed >= _length:
		enemy.queue_free()
	return null
