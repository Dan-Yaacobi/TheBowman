class_name DisenchantYieldBonus extends DisenchantBonus
## More material per disenchanted item. Rounds up, so every item gains at least 1.

@export_range(0.0, 5.0, 0.05) var extra_percent: float = 0.25

func get_description() -> String:
	return "+%d%% disenchanting resources" % roundi(extra_percent * 100.0)

func modify_yield_amount(amount: int, _slot: EquipmentData.slots, _rarity: int) -> int:
	return ceili(amount * (1.0 + extra_percent))
