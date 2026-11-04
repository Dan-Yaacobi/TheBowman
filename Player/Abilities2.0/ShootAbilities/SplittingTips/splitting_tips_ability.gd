class_name SplittingTipsAbility extends PlayerAbility
## On its first hit, an arrow splits into 2 smaller arrows angled forward. They carry your on-hit effects.

@export var split_angle_degrees: float = 25.0
## Damage of each split arrow as a share of the arrow that split.
@export var split_damage_share: float = 0.4
@export var split_scale: float = 0.65
## Safety cap: split arrows arm after this long even if still inside the enemy they came out of.
@export var max_arm_delay: float = 0.4

const SPLIT_META: StringName = &"splitting_tips_child"
const DONE_META: StringName = &"splitting_tips_done"

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if arrow == null or arrow.has_meta(SPLIT_META) or arrow.has_meta(DONE_META):
		return
	arrow.set_meta(DONE_META, true)
	var direction: Vector2 = arrow.velocity.normalized() if arrow.velocity.length() > 1.0 else Vector2.from_angle(arrow.rotation)
	var damage: int = maxi(1, roundi(arrow.damage * split_damage_share * power()))
	# Deferred: we're inside the hit's physics callback, where new areas can't be added.
	_split.call_deferred(arrow.global_position, direction, damage, arrow.knockback * split_damage_share, arrow.global_scale, _target as Enemy)

func _split(origin: Vector2, direction: Vector2, damage: int, knockback: float, arrow_scale: Vector2, source: Enemy) -> void:
	var player: Player = PlayerManager.player
	if player == null or not player.is_inside_tree():
		return
	var main_hand: PlayerMainHand = player.main_hand
	for side in [-1.0, 1.0]:
		var split: Arrow = main_hand.fire_at(direction.rotated(deg_to_rad(split_angle_degrees) * side), 0.8, origin, main_hand.get_hit_abilities(), false)
		split.set_meta(SPLIT_META, true)
		split.regular_shot = false
		split.damage = damage
		split.knockback = knockback
		split.global_scale = arrow_scale * split_scale
		# Stay unarmed until clear of the enemy they came out of (fire_arrow arms on the first frame).
		split.enabled = true
		split.enable_arrow(false)
		var armer: SplitArmer = SplitArmer.new()
		armer.source = source
		armer.max_delay = max_arm_delay
		split.add_child(armer)

func get_tooltip() -> String:
	return "Arrows split into 2 smaller arrows on their first hit"

func get_tooltip_color() -> Color:
	return Color(0.95, 0.8, 0.5)

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

## Arms its split arrow once it has passed out of the source enemy's hitbox and is moving away
## (splits start at the entry point, so they fly through the enemy first), or after max_delay.
class SplitArmer extends Node:
	const CLEAR_MARGIN: float = 4.0
	var source: Enemy
	var max_delay: float = 0.4
	var _age: float = 0.0
	var _last_dist: float = INF

	func _physics_process(delta: float) -> void:
		var arrow: Arrow = get_parent() as Arrow
		if arrow == null:
			return
		_age += delta
		if _age >= max_delay or not is_instance_valid(source) or source.is_dead or _is_clear(arrow):
			arrow.enable_arrow(true)
			queue_free()

	func _is_clear(arrow: Arrow) -> bool:
		var shape: Shape2D = source.hit_box.collision.shape if source.hit_box.collision else null
		var reach: float = shape.get_rect().size.length() / 2.0 * absf(source.hit_box.global_scale.x) if shape else 12.0
		var dist: float = arrow.global_position.distance_to(source.hit_box.global_position)
		var moving_away: bool = dist > _last_dist
		_last_dist = dist
		return moving_away and dist > reach + CLEAR_MARGIN
