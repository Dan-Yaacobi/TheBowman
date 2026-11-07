class_name EmberQuiverAbility extends PlayerAbility
## Arrows apply burn. A burning enemy knocked into another enemy spreads the burn to it.

const BURN_DEBUFF_PATH: String = "res://Debuffs/Burned/BurnDebuff.tscn"

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	if enemy == null or enemy.is_dead or MinorHitHelpers.arrow_of(_activator) == null:
		return
	apply_burn(enemy)
	if enemy.stats.can_be_knockedback:
		# Deferred: we're inside the hit's physics callback, where new areas can't be added.
		EmberSpreader.attach.call_deferred(enemy, self)

func applies_quiver_debuff() -> bool:
	return true

func apply_quiver_debuff(_target: Node2D) -> void:
	var enemy: Enemy = _target as Enemy
	if enemy and not enemy.is_dead:
		apply_burn(enemy)

## Same burn as the other fire abilities, scaled by this item's color level.
func apply_burn(enemy: Enemy) -> void:
	var stats: PlayerStats = PlayerManager.player.stats
	var burn: BurnDebuff = load(BURN_DEBUFF_PATH).instantiate()
	burn.set_damage(maxi(1, roundi(stats.burn_damage.value() * power())))
	@warning_ignore("narrowing_conversion")
	enemy.apply_debuff(burn, CustomVariables.BURN_DEBUFF_ID, stats.burn_duration.value(), stats.dot_ticks("burn"))

func get_tooltip() -> String:
	return "Arrows burn. Burning enemies knocked into others spread the burn"

func get_tooltip_color() -> Color:
	return Color.DARK_ORANGE

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

## Rides on a knocked-back burning enemy and burns every enemy it flies into.
class EmberSpreader extends Area2D:
	const ENEMY_HITBOX_MASK: int = 4
	const MIN_CARRY_SPEED: float = 25.0
	const MAX_LIFETIME: float = 0.8
	var carrier: Enemy
	var ability: EmberQuiverAbility
	var _burned: Array[Enemy] = []
	var _age: float = 0.0
	var _embers: CPUParticles2D

	static func attach(_carrier: Enemy, _ability: EmberQuiverAbility) -> void:
		if not is_instance_valid(_carrier) or _carrier.is_dead or _carrier.hit_box == null or _carrier.hit_box.collision == null:
			return
		for child in _carrier.get_children():
			if child is EmberSpreader:
				child.queue_free()
		var spreader: EmberSpreader = EmberSpreader.new()
		spreader.carrier = _carrier
		spreader.ability = _ability
		spreader.collision_layer = 0
		spreader.collision_mask = ENEMY_HITBOX_MASK
		spreader.monitorable = false
		var shape: CollisionShape2D = CollisionShape2D.new()
		shape.shape = _carrier.hit_box.collision.shape
		shape.transform = _carrier.hit_box.collision.transform
		spreader.add_child(shape)
		spreader.position = _carrier.hit_box.position
		_carrier.add_child(spreader)

	func _ready() -> void:
		area_entered.connect(_on_area_entered)
		_embers = CPUParticles2D.new()
		_embers.amount = 10
		_embers.lifetime = 0.35
		_embers.local_coords = false
		_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_embers.emission_sphere_radius = 5.0
		_embers.gravity = Vector2(0, -40)
		_embers.initial_velocity_min = 5.0
		_embers.initial_velocity_max = 15.0
		_embers.scale_amount_min = 1.0
		_embers.scale_amount_max = 2.0
		_embers.color = Color(1.0, 0.55, 0.15)
		add_child(_embers)

	func _physics_process(delta: float) -> void:
		_age += delta
		if not is_instance_valid(carrier) or carrier.is_dead or _age > MAX_LIFETIME or not carrier.has_debuff(CustomVariables.BURN_DEBUFF_ID):
			queue_free()
			return
		if _age > 0.05 and carrier.knockback_velocity.length() < maxf(MIN_CARRY_SPEED, carrier.stats.knockback_threshold):
			queue_free()

	func _on_area_entered(area: Area2D) -> void:
		var hit_box: EnemyHitBox = area as EnemyHitBox
		if hit_box == null:
			return
		var other: Enemy = hit_box.get_enemy()
		if other == null or other == carrier or other.is_dead or other in _burned:
			return
		_burned.append(other)
		ability.apply_burn(other)
