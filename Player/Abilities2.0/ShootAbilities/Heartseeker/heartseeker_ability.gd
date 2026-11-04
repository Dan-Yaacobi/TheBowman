class_name HeartseekerAbility extends PlayerAbility
## Perfect shots deal bonus damage based on the enemy's missing health.

## Bonus damage at (almost) zero health: 1.0 = +100%. Scales down linearly with the health left.
@export var max_bonus: float = 1.0
## Bonus above this also bursts red sparks on the enemy.
@export var spark_threshold: float = 0.3

const TEXT_COLOR: Color = Color(0.95, 0.15, 0.25)

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	var arrow: Arrow = MinorHitHelpers.arrow_of(hurt_box)
	if enemy == null or arrow == null or not arrow.perfect_shot or enemy.is_dead:
		return
	var missing: float = 1.0 - clampf(float(enemy.current_hp) / float(maxi(enemy.stats.max_hp, 1)), 0.0, 1.0)
	if missing <= 0.0:
		return
	var bonus: float = missing * max_bonus * power()
	MinorHitHelpers.add_damage_for_hit(hurt_box, bonus)
	# Red damage number for this hit only.
	hurt_box.set_text_color(TEXT_COLOR)
	hurt_box.successful_hit.connect(func(_hb: HurtBox, _hit: Area2D, _r: DamageResult) -> void:
		hurt_box.use_default_color = true, CONNECT_ONE_SHOT)
	if bonus >= spark_threshold:
		_sparks(enemy.global_position, bonus)

func _sparks(at: Vector2, bonus: float) -> void:
	var sparks: CPUParticles2D = CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.amount = clampi(roundi(6 + bonus * 10.0), 6, 20)
	sparks.lifetime = 0.4
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 60)
	sparks.initial_velocity_min = 30.0
	sparks.initial_velocity_max = 70.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color = TEXT_COLOR
	sparks.global_position = at
	sparks.z_index = 4
	sparks.finished.connect(sparks.queue_free)
	EventBus.summon_effect.emit(sparks)
	sparks.emitting = true

func get_tooltip() -> String:
	return "Perfect shots deal up to +%d%% damage based on the enemy's missing health" % roundi(max_bonus * power() * 100.0)

func get_tooltip_color() -> Color:
	return TEXT_COLOR

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
