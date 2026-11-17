class_name RockGolemDormantState extends EnemyState
## Sits still as a rock. Hardened (1 damage per hit, no debuffs or stuns); ignores knockback and capture.
## Wakes when the player comes close or when it gets hit.

@export var wake_state: EnemyState

var golem: RockGolem


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.set_dormant(true)
	golem.was_hit_while_dormant = false
	golem.move_x = 0.0
	golem.update_animation("Dormant")


func Physics(_delta: float) -> EnemyState:
	if golem.was_hit_while_dormant:
		return wake_state
	if PlayerManager.player and golem.calculate_distance_to_player() <= golem.golem_data.wake_range:
		return wake_state
	return null
