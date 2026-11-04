class_name LongShotAbility extends PlayerAbility
## Arrows deal more damage the farther they fly before hitting, up to +max_bonus at full_range.
## The arrow brightens and trails sparks as it gains damage.

@export var max_bonus: float = 0.6
## Flight distance (pixels) for the full bonus.
@export var full_range: float = 220.0

var _trail: LongShotTrail

func on_equipped() -> void:
	if _trail == null:
		_trail = LongShotTrail.new()
		_trail.ability = self
	var effects: Array[ArrowEffect] = PlayerManager.player.stats.arrow_visual_effects
	if not _trail in effects:
		effects.append(_trail)

func on_unequipped() -> void:
	PlayerManager.player.stats.arrow_visual_effects.erase(_trail)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var hurt_box: HurtBox = _activator as HurtBox
	var arrow: Arrow = MinorHitHelpers.arrow_of(hurt_box)
	if arrow == null:
		return
	var tracker: LongShotTracker = arrow.get_node_or_null(LongShotTracker.NODE_NAME) as LongShotTracker
	if tracker == null:
		return
	var bonus: float = tracker.charge() * max_bonus * power()
	if bonus > 0.0:
		MinorHitHelpers.add_damage_for_hit(hurt_box, bonus)

func get_tooltip() -> String:
	return "Arrows deal up to +%d%% damage the farther they fly" % roundi(max_bonus * power() * 100.0)

func get_tooltip_color() -> Color:
	return Color(1.0, 0.85, 0.45)

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

## Gives every arrow a distance tracker while Long Shot is equipped (same system as the Shadow arrows).
class LongShotTrail extends ArrowEffect:
	var ability: LongShotAbility

	func apply_effect(_arrow: Arrow) -> void:
		if _arrow == null or _arrow.has_node(LongShotTracker.NODE_NAME):
			return
		var tracker: LongShotTracker = LongShotTracker.new()
		tracker.name = LongShotTracker.NODE_NAME
		tracker.full_range = ability.full_range
		_arrow.add_child(tracker)

## Counts how far its arrow has flown since release, and brightens the arrow with it.
class LongShotTracker extends Node2D:
	const NODE_NAME: String = "LongShotTracker"
	const BRIGHT: Color = Color(1.7, 1.45, 0.8)
	var full_range: float = 220.0
	var travelled: float = 0.0
	var _last: Vector2
	var _started: bool = false
	var _sparks: CPUParticles2D

	func _ready() -> void:
		_sparks = CPUParticles2D.new()
		_sparks.emitting = false
		_sparks.local_coords = false
		_sparks.amount = 16
		_sparks.lifetime = 0.25
		_sparks.gravity = Vector2.ZERO
		_sparks.spread = 15.0
		_sparks.direction = Vector2.LEFT
		_sparks.initial_velocity_min = 5.0
		_sparks.initial_velocity_max = 15.0
		_sparks.scale_amount_min = 1.0
		_sparks.scale_amount_max = 1.5
		_sparks.color = Color(1.0, 0.85, 0.45)
		add_child(_sparks)

	func charge() -> float:
		return clampf(travelled / maxf(full_range, 1.0), 0.0, 1.0)

	func _physics_process(_delta: float) -> void:
		var arrow: Arrow = get_parent() as Arrow
		if arrow == null or not arrow.fired:
			return
		if not _started:
			_started = true
			_last = arrow.global_position
			return
		travelled += arrow.global_position.distance_to(_last)
		_last = arrow.global_position
		var t: float = charge()
		arrow.sprite.self_modulate = Color.WHITE.lerp(BRIGHT, t)
		_sparks.emitting = t > 0.25
		_sparks.color.a = t
