class_name CleanKillAbility extends PlayerAbility
## Power milestone. Killing an enemy with a perfect shot makes your next arrow perfect.
## Uses the shared charged shot (PlayerMainHand.charge_perfect_shot).

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if arrow == null or not arrow.perfect_shot or not _target is Enemy:
		return
	if _result == null or not _result.killed:
		return
	PlayerManager.player.main_hand.charge_perfect_shot()

func get_tooltip() -> String:
	return "Killing an enemy with a perfect shot makes your next arrow perfect"

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
