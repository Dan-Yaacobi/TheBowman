class_name LongShotAbility extends PlayerAbility
## Arrows that barely travel deal less damage; past full_damage_range they deal full damage,
## then gain more the farther they fly, up to +max_bonus at max_range.
## The arrow brightens and trails sparks as it gains the bonus.

## Damage lost at point blank (0.4 = -40%), easing to none at full_damage_range.
@export var short_range_penalty: float = 0.4
## Flight distance (pixels) where arrows reach full damage and the bonus starts.
@export var full_damage_range: float = 100.0
@export var max_bonus: float = 0.6
## Flight distance (pixels) for the full bonus.
@export var max_range: float = 300.0

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
	var bonus: float = damage_bonus(tracker.travelled)
	if not is_zero_approx(bonus):
		MinorHitHelpers.add_damage_for_hit(hurt_box, bonus)

## Damage change for an arrow that flew this far: negative up close, 0 at full_damage_range,
## rising to +max_bonus (scaled by color level) at max_range.
func damage_bonus(distance: float) -> float:
	if distance < full_damage_range:
		return -short_range_penalty * (1.0 - distance / maxf(full_damage_range, 1.0))
	var t: float = (distance - full_damage_range) / maxf(max_range - full_damage_range, 1.0)
	return clampf(t, 0.0, 1.0) * max_bonus * power()

func get_tooltip() -> String:
	return "Close shots deal up to %d%% less damage. Past mid range, arrows deal up to +%d%% damage the farther they fly" % [
		roundi(short_range_penalty * 100.0), roundi(max_bonus * power() * 100.0)]

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
		tracker.full_damage_range = ability.full_damage_range
		tracker.max_range = ability.max_range
		_arrow.add_child(tracker)

## Counts how far its arrow has flown since release, and brightens the arrow with it.
class LongShotTracker extends Node2D:
	const NODE_NAME: String = "LongShotTracker"
	const BRIGHT: Color = Color(1.7, 1.45, 0.8)
	var full_damage_range: float = 100.0
	var max_range: float = 300.0
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

	## 0 until full damage range, 1 at max range (drives the glow).
	func charge() -> float:
		return clampf((travelled - full_damage_range) / maxf(max_range - full_damage_range, 1.0), 0.0, 1.0)

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
