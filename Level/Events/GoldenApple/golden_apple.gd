class_name GoldenApple extends Enemy

## Skittish golden apple chased in the Golden Apple event.
## Every direct hit deals exactly 1 damage regardless of gear and drops gold
## (stats.avg_coins_dropped per hit). DoT ticks are ignored.
## Movement: Hover -> Dart legs -> (hit) Flee burst. Gets harder with every hit.
## escape() (time's up) makes it immune and it flies off the scene.

signal escaped

const HIT_DAMAGE: int = 1
const HIT_TEXT_COLOR: Color = Color.GOLD

@export_group("Flight")
## Area the apple flies in, relative to where it starts.
@export var flight_area: Rect2 = Rect2(-340.0, -100.0, 580.0, 230.0)
@export var min_dart_distance: float = 60.0
@export var max_dart_distance: float = 170.0
## Chance to stop and hover after each dart leg.
@export_range(0.0, 1.0) var hover_chance: float = 0.35
@export var hover_duration: float = 1.0
## Hovering ends early when the player gets this close.
@export var spook_distance: float = 60.0

@export_group("When Hit")
@export var flee_speed_multiplier: float = 3.0
@export var flee_duration: float = 0.35
## Max random spread of the flee direction, in degrees.
@export var flee_spread: float = 30.0
## Per hit taken: +this fraction of speed, hovers shortened by the same factor,
## and one more dart candidate sampled (it picks the one farthest from the player).
@export var difficulty_per_hit: float = 0.15

@export_group("Escape")
@export var escape_duration: float = 1.5
## Speed at the end of the escape, as a multiple of flight speed.
@export var escape_speed_multiplier: float = 4.0

@onready var flee_state: GoldenAppleFleeState = $EnemyStateMachine/Flee
@onready var escape_state: GoldenAppleEscapeState = $EnemyStateMachine/Escape
@onready var hit_box_shape: CollisionShape2D = $HitBox/CollisionShape2D

var _home: Vector2 = Vector2.ZERO

func extra_ready_functions() -> void:
	debuff_immune = true
	_home = global_position
	state_machine.Initialize(self)

func _physics_process(_delta: float) -> void:
	if not is_zero_approx(velocity.x):
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()

func _handle_take_damage(_hurt_box: HurtBox, _raw_damage, _result: DamageResult = null, _alter_dmg_color: Color = Color.WHITE) -> void:
	# DoT ticks come in without a hurt box; only direct hits count
	if is_dead or invincible or _hurt_box == null:
		return
	current_hp -= HIT_DAMAGE
	show_damage(HIT_DAMAGE, HIT_TEXT_COLOR)
	EventBus.drop_item.emit(CustomVariables.items.COIN, global_position, 100.0, stats.avg_coins_dropped)
	if current_hp <= 0:
		is_dead = true
		activate_death_ability()
		enemy_died()
		if _result:
			_result.killed = true
	else:
		_flee()

func _flee() -> void:
	if state_machine.curr_state == flee_state:
		flee_state.restart()
	else:
		state_machine.ChangeState(flee_state)

## Time's up: immune, arrows pass through, flies off and frees itself.
func escape() -> void:
	if is_dead or invincible:
		return
	invincible = true
	hit_box_shape.set_deferred("disabled", true)
	state_machine.ChangeState(escape_state)

func finish_escape() -> void:
	if is_queued_for_deletion():
		return
	escaped.emit()
	queue_free()

func hits_taken() -> int:
	return stats.max_hp - current_hp

func difficulty() -> float:
	return 1.0 + difficulty_per_hit * hits_taken()

func flight_speed() -> float:
	return stats.move_speed.value() * difficulty()

func hover_time() -> float:
	return hover_duration / difficulty()

func get_flight_rect() -> Rect2:
	return Rect2(_home + flight_area.position, flight_area.size)

func is_player_near() -> bool:
	var player: Node2D = PlayerManager.player
	return is_instance_valid(player) and global_position.distance_to(player.global_position) <= spook_distance

## Skittish: samples more candidates as it takes hits and keeps the one farthest from the player.
func pick_dart_target() -> Vector2:
	var player: Node2D = PlayerManager.player
	var candidates: int = 1 + hits_taken()
	var best: Vector2 = _random_dart_point()
	if not is_instance_valid(player):
		return best
	for i: int in candidates - 1:
		var point: Vector2 = _random_dart_point()
		if point.distance_to(player.global_position) > best.distance_to(player.global_position):
			best = point
	return best

func get_flee_direction() -> Vector2:
	var player: Node2D = PlayerManager.player
	var away: Vector2 = Vector2.UP
	if is_instance_valid(player) and not global_position.is_equal_approx(player.global_position):
		away = (global_position - player.global_position).normalized()
	return away.rotated(deg_to_rad(randf_range(-flee_spread, flee_spread)))

func _random_dart_point() -> Vector2:
	var rect: Rect2 = get_flight_rect()
	var dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
	var distance: float = randf_range(min_dart_distance, max_dart_distance)
	var point: Vector2 = global_position + dir * distance
	if not rect.has_point(point):
		# Bounce off the edge instead of hugging it
		point = global_position - dir * distance
	return point.clamp(rect.position, rect.end)
