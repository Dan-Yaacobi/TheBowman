class_name FrostRaySpell extends WizardSpellState
## Wind-up (CastForward), then a harmless aim line that builds to full strength (CastForwardHold).
## Once fully powered it hurts and slowly turns to follow the player, then fades out.

enum Phase {WIND_UP, CHARGE, FIRE, FADE, DONE}

@export var ray_scene: PackedScene
@export var hold_animation: String = "CastForwardHold"
## Seconds the beam takes to build from an aim line to full strength (harmless)
@export var charge_time: float = 1.2
## Seconds the full-power beam hurts and tracks
@export var fire_time: float = 3.0
@export var fade_time: float = 0.4
## How fast the beam turns toward the player while firing, in degrees per second
@export var turn_speed_deg: float = 14.0
## How far the beam may swing from straight ahead, in degrees
@export var max_aim_deg: float = 100.0
## Where the beam starts relative to the wizard when facing right (x mirrors when facing left)
@export var origin_offset: Vector2 = Vector2(5, -1)

var _phase: Phase = Phase.DONE
var _phase_time: float = 0.0
var _facing: float = 1.0
var _ray: FrostRay
var _locked_aim: float = 0.0
var _aim_applied: bool = false

func on_cast_start() -> void:
	wizard.face_the_player()
	wizard.lock_facing = true
	_facing = -1.0 if wizard.sprite.flip_h else 1.0
	_ray = null
	_set_phase(Phase.WIND_UP)

func Exit() -> void:
	super()
	wizard.lock_facing = false
	_free_ray()

func cast_process(delta: float) -> void:
	_phase_time += delta
	# The beam is added to the world deferred; wait until it is ready before driving it
	if _ray and not _ray.is_node_ready():
		return
	if _ray and not _aim_applied:
		_ray.global_position = _origin()
		_ray.set_aim(_locked_aim)
		_aim_applied = true
	match _phase:
		Phase.WIND_UP:
			if _phase_time >= _anim_length(cast_animation):
				_start_charge()
		Phase.CHARGE:
			if _ray:
				_ray.set_power(_phase_time / charge_time, true)
			if _phase_time >= charge_time:
				_start_fire()
		Phase.FIRE:
			if _ray:
				var target: float = _clamped_aim(_angle_to_player())
				_ray.set_aim(rotate_toward(_ray.get_aim(), target, deg_to_rad(turn_speed_deg) * delta))
			if _phase_time >= fire_time:
				_start_fade()
		Phase.FADE:
			if _ray:
				_ray.set_opacity(1.0 - _phase_time / fade_time)
			if _phase_time >= fade_time:
				_free_ray()
				_set_phase(Phase.DONE)
	if _ray:
		_ray.global_position = _origin()

func is_finished() -> bool:
	return _phase == Phase.DONE

func _set_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0

func _start_charge() -> void:
	wizard.update_animation(hold_animation)
	# Aim locks where the player stood when the charge began
	_locked_aim = _clamped_aim(_angle_to_player())
	_aim_applied = false
	if ray_scene:
		_ray = ray_scene.instantiate()
		enemy.tag_attack(_ray)
		_ray.set_source(wizard)
		EventBus.summon_effect.emit(_ray)
	_set_phase(Phase.CHARGE)

func _start_fire() -> void:
	if _ray:
		_ray.set_power(1.0, false)
		_ray.set_active(true)
	_set_phase(Phase.FIRE)

func _start_fade() -> void:
	if _ray:
		_ray.set_active(false)
	_set_phase(Phase.FADE)

func _free_ray() -> void:
	if is_instance_valid(_ray):
		_ray.queue_free()
	_ray = null

func _origin() -> Vector2:
	return wizard.global_position + Vector2(origin_offset.x * _facing, origin_offset.y)

func _angle_to_player() -> float:
	return (PlayerManager.player.global_position - _origin()).angle()

# Keep the beam in front of him: never swing more than max_aim_deg from straight ahead
func _clamped_aim(angle: float) -> float:
	var forward: float = 0.0 if _facing > 0.0 else PI
	var offset: float = clampf(wrapf(angle - forward, -PI, PI), -deg_to_rad(max_aim_deg), deg_to_rad(max_aim_deg))
	return forward + offset

func _anim_length(anim_name: String) -> float:
	if wizard.animation_player and wizard.animation_player.has_animation(anim_name):
		return wizard.animation_player.get_animation(anim_name).length
	return 0.0
