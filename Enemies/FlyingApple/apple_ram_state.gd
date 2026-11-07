class_name AppleRamState extends EnemyState

## Close to the player: winds up (pulls back), charges in a locked direction,
## and recoils away on a hit. Only used when stats.can_ram is on.

enum Phase { WINDUP, CHARGE, RECOIL }

const ATTACK_ANIMATION: StringName = &"Attack"
const PLAYER_COLLISION_LAYER: int = 1

@export var trigger_distance: float = 80.0
@export var windup_time: float = 0.25
@export var windup_pullback_speed: float = 40.0
@export var charge_speed: float = 220.0
## Charge stops after this long if it misses.
@export var max_charge_time: float = 0.5
@export var recoil_speed: float = 160.0
@export var recoil_time: float = 0.35
## Time after a ram ends before the next one can start.
@export var cooldown: float = 1.5

@onready var seek: AppleSeekState = $"../Seek"

var _phase: Phase = Phase.WINDUP
var _phase_time_left: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _cooldown_left: float = 0.0
var _cancelled: bool = false

func init() -> void:
	enemy.hurt_box.successful_hit.connect(_on_hurt_box_successful_hit)

func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

func can_start() -> bool:
	return enemy.stats.can_ram and _cooldown_left <= 0.0 \
		and enemy.calculate_distance_to_player() <= trigger_distance

func Enter() -> void:
	# Re-entered from the damaged state mid-ram: the hit cancels the ram
	_cancelled = _cooldown_left > 0.0
	if _cancelled:
		return
	_direction = enemy.calculate_direction_to_player()
	_set_phase(Phase.WINDUP, windup_time)
	enemy.animation_player.play(ATTACK_ANIMATION)

func Exit() -> void:
	_cooldown_left = cooldown
	_set_body_blocks_player(true)

func Physics(delta: float) -> EnemyState:
	if _cancelled:
		return seek
	_phase_time_left -= delta
	var t: float = clampf(_phase_time_left / maxf(_current_phase_duration(), 0.001), 0.0, 1.0)
	match _phase:
		Phase.WINDUP:
			enemy.velocity = -_direction * windup_pullback_speed * t
			if _phase_time_left <= 0.0:
				# Lock the aim at the end of the windup
				_direction = enemy.calculate_direction_to_player()
				_set_phase(Phase.CHARGE, max_charge_time)
				# The body normally bumps the player's body, which stops the hurt box from reaching it
				_set_body_blocks_player(false)
		Phase.CHARGE:
			enemy.velocity = _direction * charge_speed
			if _is_touching_player():
				_start_recoil()
			elif _phase_time_left <= 0.0:
				return seek
		Phase.RECOIL:
			enemy.velocity = -_direction * recoil_speed * t
			if _phase_time_left <= 0.0:
				return seek
	return null

func _set_phase(phase: Phase, duration: float) -> void:
	_phase = phase
	_phase_time_left = duration

func _current_phase_duration() -> float:
	match _phase:
		Phase.WINDUP:
			return windup_time
		Phase.CHARGE:
			return max_charge_time
	return recoil_time

func _on_hurt_box_successful_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	if state_machine.curr_state != self or _phase != Phase.CHARGE:
		return
	_start_recoil()

## Bounces off even when no new hit registers (already touching, or player invulnerable).
func _is_touching_player() -> bool:
	for area: Area2D in enemy.hurt_box.get_overlapping_areas():
		if area is HitBox and area.get_parent() == PlayerManager.player:
			return true
	return false

func _set_body_blocks_player(blocks: bool) -> void:
	var body: CharacterBody2D = enemy as CharacterBody2D
	if body:
		body.set_collision_mask_value(PLAYER_COLLISION_LAYER, blocks)

func _start_recoil() -> void:
	# The base Enemy knockback pushes toward the player; drop it and bounce back instead
	enemy.knockback_velocity = Vector2.ZERO
	_direction = enemy.calculate_direction_to_player()
	_set_phase(Phase.RECOIL, recoil_time)
