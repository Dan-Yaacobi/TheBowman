class_name SeekerDartsAbility extends PlayerAbility
## Non-perfect arrows home in slightly on the nearest enemy ahead. Perfect arrows fly straight and deal less
## damage: the aim assist is the payoff. The color level scales the homing, not the penalty.

## Max turn speed (radians per second) of a homing arrow.
@export var turn_rate: float = 2.5
@export var seek_radius: float = 140.0
## Only enemies within this angle of the arrow's flight are chased.
@export var seek_cone_degrees: float = 60.0
## Perfect shot damage taken away (0.25 = -25%).
@export var perfect_damage_penalty: float = 0.25

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = _activator as Arrow
	if arrow == null:
		return
	if arrow.perfect_shot:
		arrow.damage = maxi(1, roundi(arrow.damage * (1.0 - perfect_damage_penalty)))
		return
	var homing: SeekerHoming = SeekerHoming.new()
	homing.turn_rate = turn_rate * power()
	homing.seek_radius = seek_radius
	homing.cone = deg_to_rad(seek_cone_degrees)
	arrow.add_child(homing)

func get_tooltip() -> String:
	return "Normal arrows home in slightly. Perfect arrows deal %d%% less damage" % roundi(perfect_damage_penalty * 100.0)

func get_tooltip_color() -> Color:
	return Color(0.55, 0.95, 0.75)

func get_type() -> TriggerType:
	return TriggerType.RELEASE

## Steers its arrow toward the closest enemy in front of it.
class SeekerHoming extends Node:
	const RETARGET_TIME: float = 0.1
	var turn_rate: float = 2.5
	var seek_radius: float = 140.0
	var cone: float = 1.0
	var _target: Enemy
	var _retarget: float = 0.0

	func _physics_process(delta: float) -> void:
		var arrow: Arrow = get_parent() as Arrow
		if arrow == null or not arrow.fired or arrow.velocity.length() < 1.0:
			return
		_retarget -= delta
		if _retarget <= 0.0 or not is_instance_valid(_target) or _target.is_dead:
			_retarget = RETARGET_TIME
			_target = _find_target(arrow)
		if _target == null:
			return
		var desired: float = (_target.hit_box.global_position - arrow.global_position).angle()
		var angle: float = rotate_toward(arrow.velocity.angle(), desired, turn_rate * delta)
		arrow.velocity = Vector2.from_angle(angle) * arrow.velocity.length()

	func _find_target(arrow: Arrow) -> Enemy:
		var best: Enemy = null
		var best_dist: float = INF
		for enemy in MinorHitHelpers.enemies_in_radius(arrow.get_world_2d(), arrow.global_position, seek_radius):
			var to_enemy: Vector2 = enemy.hit_box.global_position - arrow.global_position
			if absf(angle_difference(arrow.velocity.angle(), to_enemy.angle())) > cone:
				continue
			if to_enemy.length_squared() < best_dist:
				best_dist = to_enemy.length_squared()
				best = enemy
		return best
