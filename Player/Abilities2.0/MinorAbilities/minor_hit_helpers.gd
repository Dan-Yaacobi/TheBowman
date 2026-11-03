class_name MinorHitHelpers
## Shared helpers for minor abilities.
## Changes to a HurtBox made in a BEFORE_HIT effect are undone once that hit lands, the same way
## CritResetAbility cleans up after a crit, so reused hurt boxes (the sword) never keep them.

const ENEMY_HITBOX_MASK: int = 4

## +bonus damage (0.25 = +25%) for this one hit only.
static func add_damage_for_hit(hurt_box: HurtBox, bonus: float) -> void:
	hurt_box.damage_multiplier.append(bonus)
	hurt_box.successful_hit.connect(func(_hb: HurtBox, _hit: Area2D, _r: DamageResult) -> void:
		hurt_box.damage_multiplier.erase(bonus), CONNECT_ONE_SHOT)

## Knockback x mult for this one hit only.
static func scale_knockback_for_hit(hurt_box: HurtBox, mult: float) -> void:
	var original: float = hurt_box.knockback_power
	hurt_box.knockback_power = original * mult
	hurt_box.successful_hit.connect(func(_hb: HurtBox, _hit: Area2D, _r: DamageResult) -> void:
		hurt_box.knockback_power = original, CONNECT_ONE_SHOT)

## The arrow behind a hurt box, or null for other hurt boxes (sword, explosions...).
static func arrow_of(hurt_box: Node) -> Arrow:
	return hurt_box.get_parent() as Arrow if hurt_box else null

## Living enemies whose hitbox is within radius of a point.
static func enemies_in_radius(world: World2D, center: Vector2, radius: float) -> Array[Enemy]:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, center)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = ENEMY_HITBOX_MASK
	var found: Array[Enemy] = []
	for hit in world.direct_space_state.intersect_shape(params, 64):
		var area: EnemyHitBox = hit.collider as EnemyHitBox
		if area and area.get_enemy() and not area.get_enemy().is_dead and not area.get_enemy() in found:
			found.append(area.get_enemy())
	return found
