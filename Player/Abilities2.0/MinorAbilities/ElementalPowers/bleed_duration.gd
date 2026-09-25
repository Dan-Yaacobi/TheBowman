class_name BleedDurationMinor extends MinorAbility


func on_equipped() -> void:
	dynamic_debuff_id = CustomVariables.get_buff_id()
	PlayerManager.player.stats.bleed_duration.add_buff(dynamic_debuff_id,value,Stat.buff_type.ADDITIVE)

func on_unequipped() -> void:
	PlayerManager.player.stats.bleed_duration.remove_buff_completly(dynamic_debuff_id,Stat.buff_type.ADDITIVE)

func get_tooltip() -> String:
	return "Increase Bleed Duration By %d" %value
	
func get_type() -> TriggerType:
	return TriggerType.PASSIVE
