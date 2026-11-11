class_name TelegraphedShotMinor extends MinorAbility
## After enough arrows hit an enemy, your next shot is charged: the draw fills instantly and fires
## perfect (the shared charged shot, PlayerMainHand.charge_perfect_shot). Pips above the archer
## show progress. Misses don't count, piercing arrows count once, and the charged arrow itself
## never counts. Hits needed = max(value, 2) - 1.

const COUNTED_META: StringName = &"telegraphed_shot_counted"
## Above Perfect Streak's pips, so both can show at once.
const PIPS_OFFSET: Vector2 = Vector2(0, -40)

var _hits_since_charge: int = 0
var _pips: PerfectStreakMinor.StreakPips

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_arrow_enemy_hit)
	if not player.main_hand.perfect_shot_cleared.is_connected(_on_perfect_shot_cleared):
		player.main_hand.perfect_shot_cleared.connect(_on_perfect_shot_cleared)
	if not is_instance_valid(_pips):
		_pips = PerfectStreakMinor.StreakPips.new()
		_pips.needed = _hits_needed()
		player.add_child(_pips)
		_pips.position = PIPS_OFFSET
	_update_pips()

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_arrow_enemy_hit)
	if main_hand.perfect_shot_cleared.is_connected(_on_perfect_shot_cleared):
		main_hand.perfect_shot_cleared.disconnect(_on_perfect_shot_cleared)
	main_hand.clear_perfect_shot()
	if is_instance_valid(_pips):
		_pips.queue_free()
	_pips = null

func _on_arrow_enemy_hit(_perfect: bool, arrow: Arrow, _target: Enemy) -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.has_perfect_shot() or not is_instance_valid(arrow):
		return
	if arrow.has_meta(PlayerMainHand.AUTO_PERFECT_META) or arrow.has_meta(COUNTED_META):
		return
	arrow.set_meta(COUNTED_META, true)
	_hits_since_charge += 1
	if _hits_since_charge >= _hits_needed():
		_hits_since_charge = 0
		main_hand.charge_perfect_shot()
	_update_pips()

func _on_perfect_shot_cleared() -> void:
	_update_pips()

## Full (glowing) while charged, otherwise one pip per counted hit.
func _update_pips() -> void:
	if not is_instance_valid(_pips):
		return
	var charged: bool = PlayerManager.player.main_hand.has_perfect_shot()
	_pips.set_count(_pips.needed if charged else _hits_since_charge)

func _hits_needed() -> int:
	return maxi(value, 2) - 1

func get_tooltip() -> String:
	return "After %d arrow hits, your next draw is instant and perfect" % _hits_needed()

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.GOLD
