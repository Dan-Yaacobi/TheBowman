class_name AppleSeekState extends EnemyState

## Islands' collision layer (5)
const ISLAND_MASK: int = 16

@onready var shoot: AppleShootState = $"../Shoot"
@onready var ray_cast_up: RayCast2D = $"../../RayCastUp"
@onready var ray_cast_down: RayCast2D = $"../../RayCastDown"
@onready var ray_cast_forward: RayCast2D = $"../../RayCastForward"
## Optional: only scenes with a Ram state (and stats.can_ram) charge the player.
@onready var ram: AppleRamState = get_node_or_null("../Ram")

## How far past the body's edge the avoidance rays look for islands.
@export var ray_margin: float = 12.0
## Moving slower than this fraction of move speed while pushing into something counts as stuck.
@export_range(0.0, 1.0) var stuck_speed_ratio: float = 0.2
## Stuck this long: flip the avoidance side.
@export var stuck_time_limit: float = 0.4

var hit_counter: int
var direction: Vector2
var succesfull_hit: bool
## Set from the body's collision shape in init(): radius + ray_margin.
var ray_length: float = 10.0
var _stuck_time: float = 0.0

var _avoidance_dir: Vector2 = Vector2.ZERO
var _clear_timer: float = 0.0
var _clear_duration: float = 0.3

func init() -> void:
	enemy.hurt_box.successful_hit.connect(hit_player)
	_fit_raycasts_to_body()

## Rays start at the body's centre and reach ray_margin past its edge.
## Shorter than the body radius, they could never see an island before the body was stuck on it.
func _fit_raycasts_to_body() -> void:
	var body_shape: CollisionShape2D = enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape == null or body_shape.shape == null:
		return
	var size: Vector2 = body_shape.shape.get_rect().size
	ray_length = maxf(size.x, size.y) * 0.5 + ray_margin
	for ray: RayCast2D in [ray_cast_up, ray_cast_down, ray_cast_forward]:
		ray.position = body_shape.position

func Enter() -> void:
	succesfull_hit = false
	hit_counter = 0
	enemy.animation_player.play("Move")
func Exit() -> void:
	succesfull_hit = false

func Process(_delta: float) -> EnemyState:
	enemy.knockback_velocity = enemy.knockback_velocity.lerp(Vector2.ZERO, enemy.stats.knockback_decay * _delta * 60)
	direction = enemy.calculate_direction_to_player()
	if enemy.knockback_velocity.length() > enemy.stats.knockback_threshold:
		enemy.velocity = enemy.knockback_velocity
	return null

func Physics(_delta: float) -> EnemyState:
	if ram and ram.can_start():
		return ram
	if enemy.stats.pure_ranged_mode:
		if enemy.calculate_distance_to_player() < enemy.stats.ranged_trigger_distance:
			succesfull_hit = true
	if succesfull_hit and enemy.stats.shooter:
		return shoot
	else:
		_update_stuck(_delta)
		var move_dir: Vector2 = _get_avoidance_direction(direction)
		var target_velocity: Vector2 = move_dir * enemy.stats.move_speed.value()
		if enemy.stats.acceleration <= 0.0:
			enemy.velocity = target_velocity
		else:
			enemy.velocity = enemy.velocity.move_toward(target_velocity, enemy.stats.acceleration * _delta)
	return null

## Pressed against an island and barely moving: try the other way around it.
func _update_stuck(delta: float) -> void:
	var body: CharacterBody2D = enemy as CharacterBody2D
	var wanted_speed: float = enemy.stats.move_speed.value()
	if body == null or wanted_speed <= 0.0:
		return
	if _is_touching_island(body) and body.get_real_velocity().length() < wanted_speed * stuck_speed_ratio:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	if _stuck_time < stuck_time_limit:
		return
	_stuck_time = 0.0
	_clear_timer = 0.0
	if _avoidance_dir != Vector2.ZERO:
		_avoidance_dir = -_avoidance_dir
	else:
		_avoidance_dir = direction.rotated(PI / 2 if randf() < 0.5 else -PI / 2)

func _is_touching_island(body: CharacterBody2D) -> bool:
	for i: int in body.get_slide_collision_count():
		var other: CollisionObject2D = body.get_slide_collision(i).get_collider() as CollisionObject2D
		if other and other.collision_layer & ISLAND_MASK:
			return true
	return false

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
		# Boxed in: back off; the stuck check picks a side once there's room
		return -desired_dir
	return _avoidance_dir

func hit_player(_var, _var2, _var3) -> void:
	if state_machine.curr_state != self:
		return
	hit_counter += 1
	if hit_counter >= enemy.stats.hits_required:
		succesfull_hit = true
