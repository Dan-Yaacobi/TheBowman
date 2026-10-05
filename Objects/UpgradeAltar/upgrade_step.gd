class_name UpgradeStep extends Resource
## One stat bump inside an UpgradeTrack's cycle.

## Special stat_name for the Max HP track: each application adds one heart container.
const HEARTS: StringName = &"hearts"

## Name of a Stat field on PlayerStats (e.g. "arrow_damage"), or "hearts".
@export var stat_name: StringName
@export var amount: float = 1.0
## Ignored for hearts.
@export var type: Stat.buff_type = Stat.buff_type.ADDITIVE
## How many times this step can apply in total. 0 = no cap.
## Once capped, the track's fallback step is used in its place.
@export var max_applications: int = 0
## Shown in the menu, e.g. "+1 Damage" or "+5% Crit Chance". Leave empty to auto-generate.
@export var display_text: String = ""

func get_display_text() -> String:
	if display_text != "":
		return display_text
	if stat_name == HEARTS:
		return "+%d Heart" % int(amount)
	if type == Stat.buff_type.MULTIPLICATIVE:
		return "+%d%% %s" % [roundi(amount * 100.0), String(stat_name).capitalize()]
	return "+%s %s" % [str(amount), String(stat_name).capitalize()]
