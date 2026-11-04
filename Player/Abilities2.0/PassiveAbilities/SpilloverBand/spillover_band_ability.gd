class_name SpilloverBandAbility extends PlayerAbility
## When an arrow kills an enemy, the damage left over jumps to the nearest enemy as a visible bolt.

@export var jump_radius: float = 120.0

const BOLT_COLOR: Color = Color(0.6, 0.9, 1.0)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	if enemy == null or _result == null or not _result.killed or MinorHitHelpers.arrow_of(_activator) == null:
		return
	var leftover: int = -enemy.current_hp
	if leftover <= 0 or not enemy.is_inside_tree():
		return
	var next: Enemy = _nearest(enemy)
	if next == null:
		return
	var damage: int = maxi(1, roundi(leftover * power()))
	SpilloverBolt.spawn(enemy.global_position, next.global_position, BOLT_COLOR)
	next.take_damage(null, damage, null, BOLT_COLOR)
	if not next.is_dead:
		next.take_hit_effect()

func _nearest(from: Enemy) -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for other in MinorHitHelpers.enemies_in_radius(from.get_world_2d(), from.global_position, jump_radius):
		if other == from:
			continue
		var dist: float = from.global_position.distance_squared_to(other.global_position)
		if dist < best_dist:
			best_dist = dist
			best = other
	return best

func get_tooltip() -> String:
	return "Arrow kills send %d%% of their leftover damage to the nearest enemy" % roundi(power() * 100.0)

func get_tooltip_color() -> Color:
	return BOLT_COLOR

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

## A short jagged bolt between two points that fades out.
class SpilloverBolt extends Node2D:
	const SEGMENTS: int = 6
	const JITTER: float = 4.0

	static func spawn(from: Vector2, to: Vector2, color: Color) -> void:
		var bolt: SpilloverBolt = SpilloverBolt.new()
		bolt.global_position = from
		bolt.z_index = 4
		var glow: Line2D = Line2D.new()
		var core: Line2D = Line2D.new()
		var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
		var span: Vector2 = to - from
		var normal: Vector2 = span.orthogonal().normalized()
		for i in range(1, SEGMENTS):
			points.append(span * (i / float(SEGMENTS)) + normal * randf_range(-JITTER, JITTER))
		points.append(span)
		glow.points = points
		glow.width = 4.0
		glow.default_color = Color(color, 0.4)
		core.points = points
		core.width = 1.5
		core.default_color = Color(1.4, 1.6, 1.8)
		bolt.add_child(glow)
		bolt.add_child(core)
		EventBus.summon_effect.emit(bolt)

	func _ready() -> void:
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
