class_name RockGolemIdleState extends EnemyState
## Awake and standing, facing the player. Decides whether to walk, jump or wait.

@export var chase_state: EnemyState
@export var jump_state: EnemyState
@export var punch_state: EnemyState

var golem: RockGolem


func init() -> void:
	golem = enemy as RockGolem


func Enter() -> void:
	golem.move_x = 0.0
	golem.update_animation("Idle")


func Physics(delta: float) -> EnemyState:
	golem.face_the_player()
	golem.jump_cooldown_left = maxf(golem.jump_cooldown_left - delta, 0.0)
	golem.punch_cooldown_left = maxf(golem.punch_cooldown_left - delta, 0.0)
	if not golem.is_on_floor():
		return null
	if golem.punch_cooldown_left <= 0.0 and golem.is_player_in_punch_range():
		return punch_state
	var player_island: Island = golem.get_player_island()
	if player_island == null:
		return null
	if player_island == golem.current_island:
		var to_player: float = absf(PlayerManager.player.global_position.x - golem.global_position.x)
		var can_step: bool = absf(golem.get_walk_target_x() - golem.global_position.x) > 1.0
		if to_player > golem.golem_data.stop_distance and can_step:
			return chase_state
		return null
	if golem.jump_cooldown_left > 0.0:
		return null
	var next_island: Island = golem.get_next_island(player_island)
	if next_island:
		golem.jump_target = next_island
		return jump_state
	return null
