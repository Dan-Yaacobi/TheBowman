class_name BoolStatCurse extends ChallengeCurse

## Name of a bool property on PlayerStats, e.g. "can_pass_walls".
@export var stat_name: String
@export var value: bool = false

var _previous: bool = false
var _applied: bool = false

func apply(_challenge: ChallengeStoneEvent) -> void:
	var stats: PlayerStats = PlayerManager.player.stats
	var current: Variant = stats.get(stat_name)
	if typeof(current) != TYPE_BOOL:
		push_warning("BoolStatCurse: '%s' is not a bool on PlayerStats." % stat_name)
		return
	_previous = current
	stats.set(stat_name, value)
	_applied = true

func remove(_challenge: ChallengeStoneEvent) -> void:
	if not _applied:
		return
	PlayerManager.player.stats.set(stat_name, _previous)
	_applied = false
