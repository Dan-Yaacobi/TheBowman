class_name DisenchantBonus extends Resource
## Base for disenchanting milestone bonuses. The hooks do nothing by default; a new bonus type
## is a subclass overriding the hooks it needs, plus a .tres on a milestone.

## Text shown on the table, e.g. "+1 arrow damage".
func get_description() -> String:
	return ""

## 5.0 → "5", 2.5 → "2.5".
static func format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 1)

## Permanent player stat bonus. Called once per stack; buff_id is unique to this bonus.
func apply_to_stats(_stats: PlayerStats, _buff_id: int) -> void:
	pass

## Removes everything apply_to_stats added under buff_id.
func clear_from_stats(_stats: PlayerStats, _buff_id: int) -> void:
	pass
