class_name BurnTicksMinor extends MinorAbility

func on_equipped() -> void:
	dynamic_debuff_id = CustomVariables.get_buff_id()
	PlayerManager.player.stats.burn_ticks.add_buff(dynamic_debuff_id,value,Stat.buff_type.MULTIPLICATIVE)

func on_unequipped() -> void:
	PlayerManager.player.stats.burn_ticks.remove_buff_completly(dynamic_debuff_id,Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Burn Does Damage x%d Faster" % value
	
func get_type() -> TriggerType:
	return TriggerType.PASSIVE
