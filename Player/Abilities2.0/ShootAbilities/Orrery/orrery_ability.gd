class_name OrreryAbility extends PlayerAbility
## Orrery: quick (non-perfect) shots don't fly off: they orbit you (up to max_orbiting), striking
## enemies that come close. A perfect shot launches every orbiting arrow along your aim with it.
## With the orbit full, quick shots fly normally.

@export var max_orbiting: int = 3
@export var orbit_radius: float = 30.0
## Radians per second.
@export var orbit_speed: float = 4.0

var _orbit: OrbitRing

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(_orbit):
		_orbit = OrbitRing.new()
		_orbit.radius = orbit_radius
		_orbit.speed = orbit_speed
		player.add_child(_orbit)

func on_unequipped() -> void:
	if is_instance_valid(_orbit):
		_orbit.clear()
		_orbit.queue_free()
	_orbit = null

## Runs on every arrow the player releases, before it flies.
func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = _activator as Arrow
	if arrow == null or not arrow.regular_shot or not is_instance_valid(_orbit):
		return
	if arrow.perfect_shot:
		_orbit.launch_all(arrow.velocity, arrow.velocity.length())
	elif _orbit.count() < max_orbiting:
		_orbit.capture(arrow)

func get_tooltip() -> String:
	return "Quick shots orbit you (up to %d). Perfect shots launch them all" % max_orbiting

func get_tooltip_color() -> Color:
	return Color(0.75, 0.85, 1.0)

func get_type() -> TriggerType:
	return TriggerType.RELEASE

## Holds the orbiting arrows around the player.
class OrbitRing extends Node:
	## Orbit center relative to the player's origin (about chest height).
	const CENTER_OFFSET: Vector2 = Vector2(0, -8)
	var radius: float = 30.0
	var speed: float = 4.0
	var _arrows: Array[Arrow] = []
	var _angle: float = 0.0

	func _ready() -> void:
		# After arrows move this frame, so the orbit position wins.
		process_physics_priority = 10

	func count() -> int:
		_prune()
		return _arrows.size()

	func capture(arrow: Arrow) -> void:
		arrow.fired = false
		arrow.velocity = Vector2.ZERO
		arrow.gravity = 0.0
		# Islands would eat an arrow circling the player's feet.
		arrow.can_pass_walls = true
		arrow.enable_arrow(true)
		_arrows.append(arrow)

	func launch_all(direction: Vector2, launch_speed: float) -> void:
		_prune()
		var dir: Vector2 = direction.normalized()
		for arrow: Arrow in _arrows:
			arrow.can_pass_walls = PlayerManager.player.stats.can_pass_walls
			arrow.gravity = 50.0
			arrow.velocity = dir * launch_speed
			arrow.fired = true
		_arrows.clear()

	func clear() -> void:
		for arrow: Arrow in _arrows:
			if is_instance_valid(arrow):
				arrow.queue_free()
		_arrows.clear()

	func _prune() -> void:
		_arrows = _arrows.filter(func(a: Arrow) -> bool: return is_instance_valid(a) and not a.is_queued_for_deletion())

	func _physics_process(delta: float) -> void:
		_prune()
		if _arrows.is_empty():
			return
		var player: Player = get_parent() as Player
		_angle = wrapf(_angle + speed * delta, 0.0, TAU)
		var center: Vector2 = player.global_position + CENTER_OFFSET
		for i: int in _arrows.size():
			var a: float = _angle + TAU * i / _arrows.size()
			var arrow: Arrow = _arrows[i]
			arrow.global_position = center + Vector2.from_angle(a) * radius
			arrow.rotation = a + PI / 2.0
			# A tiny outward velocity: hits read their knockback direction from it (push enemies away).
			arrow.velocity = Vector2.from_angle(a) * 0.01
