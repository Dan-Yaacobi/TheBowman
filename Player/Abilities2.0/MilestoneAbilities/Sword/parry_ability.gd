class_name ParryAbility extends PlayerPassiveAbility
## Sword milestone. Your sword destroys enemy projectiles (the base sword doesn't).

func on_equipped() -> void:
	PlayerManager.player.body.sword.set_destroys_projectiles(true)

func on_unequipped() -> void:
	PlayerManager.player.body.sword.set_destroys_projectiles(false)

func get_tooltip() -> String:
	return "Your sword destroys enemy projectiles"
