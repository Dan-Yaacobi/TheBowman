class_name TelegraphedShotMinor extends MinorAbility
## Every Xth arrow is automatically perfect. While the next arrow is the charged one the bow glows and
## sparks (before you draw), and the pull bar turns gold once you draw. X = value.

var _shots_since_charge: int = 0

func on_equipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if not main_hand.release.is_connected(_on_release):
		main_hand.release.connect(_on_release)

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)
	main_hand.next_shot_perfect = false

func _on_release() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.next_shot_perfect:
		return
	_shots_since_charge += 1
	if _shots_since_charge >= maxi(value, 2) - 1:
		_shots_since_charge = 0
		main_hand.next_shot_perfect = true

func get_tooltip() -> String:
	return "Every %d arrows, one is automatically perfect" % maxi(value, 2)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.GOLD
