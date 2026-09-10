class_name BirdEggAttackState extends EnemyState

@onready var seek: BirdSeekState = $"../Seek"
@onready var pre_dive: BirdPreDiveState = $"../PreDive"
@onready var egg_attack_timer: Timer = $EggAttackTimer

@export var egg_attack_min_time: float = 1.0
@export var egg_attack_max_time: float = 2.0
@export var min_end: float = 30.0
@export var max_end: float = 60.0
@export var too_close_x: float = 30
@export var too_close_y: float = 30
@export var too_far_x: float = 200
@export var too_far_y: float = 150

var fly_direction: int
var right_end: float
var left_end: float

func init() -> void:
	egg_attack_timer.timeout.connect(enemy.shoot)

	
func Enter() -> void:
	fly_direction = [-1, 1].pick_random()
	enemy.sprite.flip_h = fly_direction == 1
	
	right_end = randf_range(min_end, max_end)
	left_end = -right_end
	egg_attack_timer.wait_time = randf_range(egg_attack_min_time, egg_attack_max_time)
	egg_attack_timer.start()

func Exit() -> void:
	egg_attack_timer.stop()
	enemy.sprite.flip_h = true

func Process(_delta: float) -> EnemyState:
	update_horizontal_movement()
	enemy.velocity = Vector2(fly_direction * enemy.stats.move_speed.value(), 0)
	return check_transitions()

func Physics(_delta: float) -> EnemyState:
	return null

# --- Movement ---

func update_horizontal_movement() -> void:
	var bound = PlayerManager.player.global_position.x + (right_end if fly_direction == 1 else left_end)
	if fly_direction * enemy.global_position.x > fly_direction * bound:
		fly_direction *= -1
		enemy.sprite.flip_h = fly_direction == 1

# --- Transition checks ---

func check_transitions() -> EnemyState:
	if is_player_above() or is_too_close():
		return seek
	if is_too_far():
		return pre_dive
	return null

func is_player_above() -> bool:
	return PlayerManager.player.global_position.y < enemy.global_position.y

func is_too_close() -> bool:
	var y_dist = abs(enemy.global_position.y - PlayerManager.player.global_position.y)
	return y_dist < too_close_y

func is_too_far() -> bool:
	var x_dist = abs(enemy.global_position.x - PlayerManager.player.global_position.x)
	var y_dist = abs(enemy.global_position.y - PlayerManager.player.global_position.y)
	return x_dist > too_far_x or y_dist > too_far_y
