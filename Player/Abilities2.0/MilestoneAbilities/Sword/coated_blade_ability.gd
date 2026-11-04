class_name CoatedBladeAbility extends PlayerAbility
## Sword milestone. Sword hits apply your quiver's debuff (bleed, burn, poison, frost, stun, curse).

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var player: Player = PlayerManager.player
	if _activator == null or _activator != player.body.slash_hurt_box or not _target is Enemy:
		return
	var quiver: EquipmentData = player.stats.arrow
	if quiver and quiver.ability and quiver.ability.applies_quiver_debuff():
		quiver.ability.apply_quiver_debuff(_target)

func get_tooltip() -> String:
	return "Your sword applies your quiver's debuff"

## Before the hit, so debuffs that check the enemy's state (Stun needs full health) still work.
func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
