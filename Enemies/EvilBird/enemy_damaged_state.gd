class_name EnemyDamagedState extends EnemyState

@export var fallback_state: EnemyState
@export var animation_name: StringName = &"Damaged"

var return_state: EnemyState = null
var finished: bool = false

func init() -> void:
	enemy.animation_player.animation_finished.connect(_on_animation_finished)

func Enter() -> void:
	return_state = state_machine.prev_state
	_play()

func Exit() -> void:
	pass

func Process(_delta: float) -> EnemyState:
	if finished:
		return return_state if return_state else fallback_state
	return null

func Physics(_delta: float) -> EnemyState:
	_apply_knockback(_delta)
	return null

func restart() -> void:
	_play()

func _play() -> void:
	finished = false
	enemy.animation_player.stop()
	enemy.animation_player.play(animation_name)

func _apply_knockback(delta: float) -> void:
	var body: CharacterBody2D = enemy as CharacterBody2D
	if body == null:
		return
	if not enemy.stats.can_be_knockedback:
		body.velocity = Vector2.ZERO
		return
	var weight: float = 1.0 - exp(-enemy.stats.knockback_decay * 60.0 * delta)
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, weight)
	if enemy.knockback_velocity.length() > enemy.stats.knockback_threshold:
		body.velocity = enemy.knockback_velocity
	else:
		enemy.knockback_velocity = Vector2.ZERO
		body.velocity = Vector2.ZERO

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		finished = true
