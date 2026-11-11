class_name TelegraphedShotMinor extends MinorAbility
## After enough arrows hit an enemy, your next arrow is automatically perfect. While the next arrow is
## the charged one the bow glows and sparks (before you draw), and the pull bar turns gold once you draw.
## Misses don't count, piercing arrows count once, and the auto-perfect arrow itself never counts.
## Hits needed = max(value, 2) - 1.

const COUNTED_META: StringName = &"telegraphed_shot_counted"

var _hits_since_charge: int = 0

func on_equipped() -> void:
	if not EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_arrow_enemy_hit)

func on_unequipped() -> void:
	if EventBus.arrow_enemy_hit.is_connected(_on_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_arrow_enemy_hit)
	PlayerManager.player.main_hand.next_shot_perfect = false

func _on_arrow_enemy_hit(_perfect: bool, arrow: Arrow, _target: Enemy) -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.next_shot_perfect or not is_instance_valid(arrow):
		return
	if arrow.has_meta(PlayerMainHand.AUTO_PERFECT_META) or arrow.has_meta(COUNTED_META):
		return
	arrow.set_meta(COUNTED_META, true)
	_hits_since_charge += 1
	if _hits_since_charge >= _hits_needed():
		_hits_since_charge = 0
		main_hand.next_shot_perfect = true

func _hits_needed() -> int:
	return maxi(value, 2) - 1

func get_tooltip() -> String:
	return "After %d arrow hits, your next arrow is automatically perfect" % _hits_needed()

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.GOLD
