class_name PoisonDurationMinor extends MinorAbility

func on_equipped() -> void:
	if dynamic_debuff_id == 0:
		dynamic_debuff_id = CustomVariables.get_buff_id()
	var stat: Stat = PlayerManager.player.stats.poison_duration
	stat.remove_buff_completly(dynamic_debuff_id, Stat.buff_type.MULTIPLICATIVE)
	# value is a percent of base. Scales with the item's color level (scrolls).
	stat.add_buff(dynamic_debuff_id, value * power() / 100.0, Stat.buff_type.MULTIPLICATIVE)

func refresh_power() -> void:
	on_equipped()

func on_unequipped() -> void:
	PlayerManager.player.stats.poison_duration.remove_buff_completly(dynamic_debuff_id,Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "+%d%% Poison Duration" % roundi(value * power())
	
func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.LIME_GREEN
