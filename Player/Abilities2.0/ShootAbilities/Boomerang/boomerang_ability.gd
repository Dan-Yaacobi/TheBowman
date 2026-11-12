class_name BoomerangAbility extends PlayerPassiveAbility
## Boomerang Quiver: an arrow that flies its full range without hitting turns around and comes back
## to you, hitting enemies on the way. Perfect arrows return at full damage, others at a share.
## Arrows that hit on the way out are spent as usual. Returning arrows pass through islands.

## Distance an arrow flies before it turns back.
@export var return_range: float = 220.0
## Damage on the way back for non-perfect arrows; scales with the quiver's color level (max 100%).
@export var quick_return_share: float = 0.5

var _effect: BoomerangEffect

func on_equipped() -> void:
	if _effect == null:
		_effect = BoomerangEffect.new()
		_effect.ability = self
	var effects: Array[ArrowEffect] = PlayerManager.player.stats.arrow_visual_effects
	if not _effect in effects:
		effects.append(_effect)

func on_unequipped() -> void:
	PlayerManager.player.stats.arrow_visual_effects.erase(_effect)

func return_share() -> float:
	return minf(quick_return_share * power(), 1.0)

func get_tooltip() -> String:
	return "Arrows that miss return to you, hitting enemies on the way back (%d%% for quick shots)" % roundi(return_share() * 100.0)

func get_tooltip_color() -> Color:
	return Color(0.95, 0.75, 0.45)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

## Gives every arrow a return tracker while the quiver is equipped.
class BoomerangEffect extends ArrowEffect:
	var ability: BoomerangAbility

	func apply_effect(_arrow: Arrow) -> void:
		if _arrow == null or _arrow.has_node(BoomerangTracker.NODE_NAME):
			return
		var tracker: BoomerangTracker = BoomerangTracker.new()
		tracker.name = BoomerangTracker.NODE_NAME
		tracker.return_range = ability.return_range
		tracker.return_share = ability.return_share()
		_arrow.add_child(tracker)

## Measures its arrow's flight; at return_range it steers the arrow back to the player.
class BoomerangTracker extends Node:
	const NODE_NAME: String = "BoomerangTracker"
	## The arrow is caught once it gets this close to the player.
	const CATCH_DISTANCE: float = 14.0
	const MIN_RETURN_SPEED: float = 140.0
	var return_range: float = 220.0
	var return_share: float = 0.5
	var _travelled: float = 0.0
	var _last: Vector2
	var _started: bool = false
	var _returning: bool = false
	var _speed: float = 0.0

	func _physics_process(_delta: float) -> void:
		var arrow: Arrow = get_parent() as Arrow
		if arrow == null or not arrow.fired:
			return
		if not _started:
			_started = true
			_last = arrow.global_position
			# Only the player's own shots come back, not echoes, bounces or mirrors.
			if not arrow.regular_shot:
				queue_free()
			return
		var player: Player = PlayerManager.player
		if not _returning:
			_travelled += arrow.global_position.distance_to(_last)
			_last = arrow.global_position
			if _travelled >= return_range:
				_turn(arrow)
			return
		var to_player: Vector2 = player.global_position - arrow.global_position
		if to_player.length() <= CATCH_DISTANCE:
			if not arrow.succesfuly_hit:
				EventBus.arrow_missed.emit()
			arrow.queue_free()
			return
		arrow.velocity = to_player.normalized() * _speed

	func _turn(arrow: Arrow) -> void:
		_returning = true
		_speed = maxf(arrow.velocity.length(), MIN_RETURN_SPEED)
		arrow.gravity = 0.0
		arrow.can_pass_walls = true
		if not arrow.perfect_shot:
			arrow.damage = maxi(1, roundi(arrow.damage * return_share))
