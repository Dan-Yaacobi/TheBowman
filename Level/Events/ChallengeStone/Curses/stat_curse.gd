class_name StatCurse extends ChallengeCurse

## Name of a Stat property on PlayerStats, e.g. "perfect_shot_window".
@export var stat_name: String
@export var amount: float = -0.5
@export var type: Stat.buff_type = Stat.buff_type.MULTIPLICATIVE

func apply(_challenge: ChallengeStoneEvent) -> void:
	var stat: Stat = _get_stat()
	if stat:
		stat.add_buff(get_instance_id(), amount, type)

func remove(_challenge: ChallengeStoneEvent) -> void:
	var stat: Stat = _get_stat()
	if stat:
		stat.remove_buff_completly(get_instance_id(), type)

func _get_stat() -> Stat:
	var stat: Stat = PlayerManager.player.stats.get(stat_name) as Stat
	if stat == null:
		push_warning("StatCurse: '%s' is not a Stat on PlayerStats." % stat_name)
	return stat
