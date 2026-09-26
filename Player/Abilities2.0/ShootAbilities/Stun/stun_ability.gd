class_name StunAbility extends PlayerShootAbility

const STUN_DEBUFF = preload("uid://c1gcykybdcokh")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy:
		if _target.full_health() and _target.can_be_stunned():
			var stun_debuff: Debuff = STUN_DEBUFF.instantiate()
			var duration = PlayerManager.player.stats.stun_duration.value()
			_target.debuff_handler.add_debuff(stun_debuff,CustomVariables.STUN_DEBUFF_ID,duration,1)

func get_tooltip() -> String:
	return "Stuns Full-Health Enemies"

func get_tooltip_color() -> Color:
	return Color.YELLOW

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
