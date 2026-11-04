class_name SecondDashAbility extends PlayerPassiveAbility
## Mobility milestone. One extra dash before the dash cooldown has to run out.

func on_equipped() -> void:
	PlayerManager.player.stats.max_dashes += 1

func on_unequipped() -> void:
	PlayerManager.player.stats.max_dashes -= 1

func get_tooltip() -> String:
	return "One extra dash before the cooldown"
