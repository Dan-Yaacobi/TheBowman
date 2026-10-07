class_name FlyingTargetMoveState extends EnemyState


func init() -> void:
	pass

func Enter() -> void:
	enemy.set_route(enemy.start_position, enemy.end_position)
	
func Exit() -> void:
	pass
	
func Process(_delta: float) -> EnemyState:
	return null
	
func Physics(_delta: float) -> EnemyState:
	return null
	
