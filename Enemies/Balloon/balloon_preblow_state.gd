class_name BalloonPreBlowState extends EnemyState

@onready var blow: BalloonBlowState = $"../Blow"
@onready var idle: BalloonIdleState = $"../Idle"

func init() -> void:
	pass

func Enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.wind.disable()
	enemy.wind.reset_size()
	enemy.update_animation("PreBlow")
	enemy.animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	
func Exit() -> void:
	if enemy.animation_player.animation_finished.is_connected(_on_animation_finished):
		enemy.animation_player.animation_finished.disconnect(_on_animation_finished)
	
func Process(_delta: float) -> EnemyState:
	return null
	
func Physics(_delta: float) -> EnemyState:
	return null

func _on_animation_finished(_anim: StringName) -> void:
	state_machine.ChangeState(blow)
