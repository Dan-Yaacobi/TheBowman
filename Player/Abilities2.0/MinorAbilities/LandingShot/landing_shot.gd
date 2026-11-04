class_name LandingShotMinor extends MinorAbility
## Your first shot after landing has a value% wider perfect window.

var _buff_id: int = -1

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if _buff_id < 0:
		_buff_id = CustomVariables.get_buff_id()
	if not player.jump_action.landed.is_connected(_on_landed):
		player.jump_action.landed.connect(_on_landed)
	if not player.main_hand.release.is_connected(_remove_buff):
		player.main_hand.release.connect(_remove_buff)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.jump_action.landed.is_connected(_on_landed):
		player.jump_action.landed.disconnect(_on_landed)
	if player.main_hand.release.is_connected(_remove_buff):
		player.main_hand.release.disconnect(_remove_buff)
	_remove_buff()

func _on_landed() -> void:
	_remove_buff()
	PlayerManager.player.stats.perfect_shot_window.add_buff(_buff_id, value / 100.0 * power(), Stat.buff_type.MULTIPLICATIVE)

func _remove_buff() -> void:
	PlayerManager.player.stats.perfect_shot_window.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Your first shot after landing has a %d%% wider perfect window" % roundi(value * power())

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.KHAKI
