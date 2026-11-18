class_name DisenchantStatBonus extends DisenchantBonus
## A permanent player stat bonus, e.g. +1 arrow damage. Stacks when its milestone repeats.

## Name of a Stat field on PlayerStats, e.g. "arrow_damage".
@export var stat_name: StringName = &"arrow_damage"
@export var amount: float = 1.0
@export var type: Stat.buff_type = Stat.buff_type.ADDITIVE
## e.g. "+1 arrow damage". Empty = built from stat_name and amount.
@export var display_text: String = ""

func get_description() -> String:
	if display_text != "":
		return display_text
	return _describe(amount)

## Adds the stacks up into one number ("+3 arrow damage"); a custom display_text gets "x3".
func get_stacked_description(stacks: int) -> String:
	if display_text != "" or stacks <= 1:
		return super(stacks)
	return _describe(amount * stacks)

func _describe(total: float) -> String:
	var stat_label: String = PlayerStats.display_name(String(stat_name)).to_lower()
	if type == Stat.buff_type.MULTIPLICATIVE:
		return "+%s%% %s" % [format_number(total * 100.0), stat_label]
	return "+%s %s" % [format_number(total), stat_label]

func apply_to_stats(stats: PlayerStats, buff_id: int) -> void:
	var stat: Stat = _get_stat(stats)
	if stat:
		stat.add_buff(buff_id, amount, type)

func clear_from_stats(stats: PlayerStats, buff_id: int) -> void:
	var stat: Stat = _get_stat(stats)
	if stat:
		stat.remove_buff_completly(buff_id, type)

func _get_stat(stats: PlayerStats) -> Stat:
	var stat: Stat = stats.get(stat_name) as Stat
	if stat == null:
		push_warning("DisenchantStatBonus: '%s' is not a Stat on PlayerStats" % stat_name)
	return stat
