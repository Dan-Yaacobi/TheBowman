class_name RockGolemChaseState extends EnemyState
## Walks toward the player on its own island without stepping off the edge.

@export var idle_state: EnemyState

var golem: RockGolem


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.update_animation("Walk")


func Exit() -> void:
	golem.move_x = 0.0


func Physics(_delta: float) -> EnemyState:
	golem.face_the_player()
	if not golem.is_on_floor() or golem.get_player_island() != golem.current_island:
		return idle_state
	var to_player: float = absf(PlayerManager.player.global_position.x - golem.global_position.x)
	var step: float = golem.get_walk_target_x() - golem.global_position.x
	if to_player <= golem.golem_data.stop_distance or absf(step) <= 1.0:
		return idle_state
	golem.move_x = signf(step) * golem.stats.move_speed.value()
	return null
