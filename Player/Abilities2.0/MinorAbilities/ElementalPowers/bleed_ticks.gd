class_name BleedTicksMinor extends MinorAbility


func on_equipped() -> void:
	if dynamic_debuff_id == 0:
		dynamic_debuff_id = CustomVariables.get_buff_id()
	var stat: Stat = PlayerManager.player.stats.bleed_ticks
	stat.remove_buff_completly(dynamic_debuff_id, Stat.buff_type.MULTIPLICATIVE)
	# Scales with the item's color level (scrolls).
	stat.add_buff(dynamic_debuff_id, value * power(), Stat.buff_type.MULTIPLICATIVE)

func refresh_power() -> void:
	on_equipped()

func on_unequipped() -> void:
	PlayerManager.player.stats.bleed_ticks.remove_buff_completly(dynamic_debuff_id,Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Bleed Does Damage x%s Faster" % String.num(snappedf(value * power(), 0.1)).trim_suffix(".0")
	
func get_type() -> TriggerType:
	return TriggerType.PASSIVE
