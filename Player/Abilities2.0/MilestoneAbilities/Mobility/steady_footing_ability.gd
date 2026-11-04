class_name SteadyFootingAbility extends PlayerPassiveAbility
## Mobility milestone. You take less knockback from hits while airborne.

## 0.4 = 40% less knockback.
@export var reduction: float = 0.4

func on_equipped() -> void:
	PlayerManager.player.air_knockback_taken *= 1.0 - reduction

func on_unequipped() -> void:
	PlayerManager.player.air_knockback_taken /= 1.0 - reduction

func get_tooltip() -> String:
	return "You take %d%% less knockback while airborne" % roundi(reduction * 100.0)
