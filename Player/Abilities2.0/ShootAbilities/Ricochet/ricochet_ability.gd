class_name RicochetAbility extends PlayerAbility
## Ricochet Quiver: every arrow hit bounces once toward the nearest other enemy for a share of the
## hit's damage. With no enemy in range, it bounces off in a random direction. Bounces never bounce
## again. The damage share scales with the quiver's color level.

const BOUNCED_META: StringName = &"ricochet_bounce"

@export var damage_share: float = 0.6
@export var seek_radius: float = 220.0
## Spawn the bounce this far out from the enemy so it doesn't hit the same one again.
@export var spawn_offset: float = 24.0

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	var arrow: Arrow = MinorHitHelpers.arrow_of(hurt_box)
	if enemy == null or arrow == null or arrow.has_meta(BOUNCED_META) or not enemy.is_inside_tree():
		return
	var origin: Vector2 = enemy.global_position
	var direction: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
	var next: Enemy = _nearest_other(enemy)
	if next:
		direction = (next.global_position - origin).normalized()
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	var bounce: Arrow = main_hand.fire_at(direction, 0.99, origin + direction * spawn_offset, main_hand.get_hit_abilities(), false)
	bounce.set_meta(BOUNCED_META, true)
	bounce.regular_shot = false
	bounce.damage = maxi(1, roundi(hurt_box.damage * damage_share * power()))
	bounce.knockback = hurt_box.knockback_power * damage_share

func _nearest_other(from: Enemy) -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(from.get_world_2d(), from.global_position, seek_radius):
		if enemy == from or enemy.is_dead:
			continue
		var dist: float = enemy.global_position.distance_squared_to(from.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func get_tooltip() -> String:
	return "Every hit bounces to the nearest enemy for %d%% damage" % roundi(damage_share * power() * 100.0)

func get_tooltip_color() -> Color:
	return Color.KHAKI

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
