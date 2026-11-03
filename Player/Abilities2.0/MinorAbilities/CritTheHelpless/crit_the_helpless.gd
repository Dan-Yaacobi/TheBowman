class_name CritTheHelplessMinor extends MinorAbility
## Hits on stunned or frozen enemies always crit (same crit multiplier, colour and effect as normal crits).

const CRIT_EFFECT_PATH: String = "res://Items/ItemEffects/CriticalHit/Crit.tscn"

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null:
		return
	if not (enemy.stunned or enemy.has_debuff(CustomVariables.FREEZE_DEBUFF_ID)):
		return
	var crit_mult: float = PlayerManager.player.stats.crit_modifier.value()
	if crit_mult in hurt_box.damage_multiplier:
		return # already a crit
	MinorHitHelpers.add_damage_for_hit(hurt_box, crit_mult)
	hurt_box.set_text_color(Color.PURPLE)
	hurt_box.successful_hit.connect(func(_hb: HurtBox, _hit: Area2D, _r: DamageResult) -> void: hurt_box.use_default_color = true, CONNECT_ONE_SHOT)
	var effect: Node2D = load(CRIT_EFFECT_PATH).instantiate()
	effect.global_position = enemy.global_position
	EventBus.summon_effect.emit(effect)

func get_tooltip() -> String:
	return "Hits on stunned or frozen enemies always crit"

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

func get_tooltip_color() -> Color:
	return Color.MEDIUM_PURPLE
