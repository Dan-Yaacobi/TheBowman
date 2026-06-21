class_name AppleSeekState extends EnemyState

@onready var shoot: AppleShootState = $"../Shoot"
@onready var ray_cast_up: RayCast2D = $"../../RayCastUp"
@onready var ray_cast_down: RayCast2D = $"../../RayCastDown"
@onready var ray_cast_forward: RayCast2D = $"../../RayCastForward"

var direction: Vector2
var distance_to_strike: int = 30
var succesfull_hit: bool
var ray_length: float = 10.0

var _avoidance_dir: Vector2 = Vector2.ZERO
var _clear_timer: float = 0.0
var _clear_duration: float = 0.3
func init() -> void:
	enemy.hurt_box.successful_hit.connect(hit_player)

func Enter() -> void:
	succesfull_hit = false

func Exit() -> void:
	succesfull_hit = false

func Process(_delta: float) -> EnemyState:
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
	return null

func Physics(_delta: float) -> EnemyState:
	var modifier: int = 1
	if enemy.calculate_distance_to_player() <= distance_to_strike:
		modifier = 2
	if succesfull_hit:
		return shoot
	else:
		var move_dir: Vector2 = _get_avoidance_direction(direction)
		enemy.velocity = move_dir * enemy.stats.move_speed.value() * modifier
	return null

func _update_raycasts(desired_dir: Vector2) -> void:
	var perp: Vector2 = desired_dir.rotated(PI / 2)
	ray_cast_forward.target_position = desired_dir * ray_length
	ray_cast_up.target_position = perp * ray_length
	ray_cast_down.target_position = -perp * ray_length
	ray_cast_forward.force_raycast_update()
	ray_cast_up.force_raycast_update()
	ray_cast_down.force_raycast_update()

func _get_avoidance_direction(desired_dir: Vector2) -> Vector2:
	_update_raycasts(desired_dir)
	if not ray_cast_forward.is_colliding():
		if _avoidance_dir != Vector2.ZERO:
			_clear_timer += get_physics_process_delta_time()
			if _clear_timer >= _clear_duration:
				_avoidance_dir = Vector2.ZERO
				_clear_timer = 0.0
		return _avoidance_dir if _avoidance_dir != Vector2.ZERO else desired_dir
	_clear_timer = 0.0
	if _avoidance_dir != Vector2.ZERO:
		return _avoidance_dir
	var up_clear: bool = not ray_cast_up.is_colliding()
	var down_clear: bool = not ray_cast_down.is_colliding()
	if up_clear and down_clear:
		var perp: Vector2 = desired_dir.rotated(PI / 2)
		var player_pos: Vector2 = PlayerManager.player.global_position
		var up_dist: float = (enemy.global_position + perp).distance_to(player_pos)
		var down_dist: float = (enemy.global_position - perp).distance_to(player_pos)
		_avoidance_dir = perp if up_dist < down_dist else -perp
	elif up_clear:
		_avoidance_dir = desired_dir.rotated(PI / 2)
	elif down_clear:
		_avoidance_dir = -desired_dir.rotated(PI / 2)
	else:
		return desired_dir
	return _avoidance_dir

func hit_player(_var) -> void:
	if state_machine.curr_state != self:
		return
	succesfull_hit = true
