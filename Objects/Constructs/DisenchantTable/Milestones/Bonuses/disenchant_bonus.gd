class_name DisenchantBonus extends Resource
## Base for disenchanting milestone bonuses. Each hook gets the current value (after earlier
## bonuses) and returns it changed; the defaults change nothing. A new bonus type is a new
## subclass overriding the hooks it needs, plus a .tres on a milestone.

## Text shown on the table, e.g. "+25% disenchanting resources".
func get_description() -> String:
	return ""

## 5.0 → "5", 2.5 → "2.5".
static func format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 1)

## Material amount one disenchanted item gives.
func modify_yield_amount(amount: int, _slot: EquipmentData.slots, _rarity: int) -> int:
	return amount

## Chance (%) a legendary also gives a Skyshard.
func modify_skyshard_chance(chance: float) -> float:
	return chance

## Chance (%) of a chance-based equipment drop in a run (enemies; chests already drop at 100%).
func modify_equipment_drop_chance(chance: float) -> float:
	return chance

## Lowest rarity (EquipmentData.Rarity) the first equipment drop of each run can roll. -1 = no minimum.
func modify_first_drop_min_rarity(min_rarity: int) -> int:
	return min_rarity
