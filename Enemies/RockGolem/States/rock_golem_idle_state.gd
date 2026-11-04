class_name RockGolemIdleState extends EnemyState
## Awake and standing, facing the player. Chase/jump/charge/throw branch from here in later steps.

var golem: RockGolem


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	golem.update_animation("Idle")


func Physics(_delta: float) -> EnemyState:
	golem.face_the_player()
	return null
