class_name SwordCooldownAbility extends PlayerSwordAbility

var sword_cd_reduction: float = 0.1

func add_ability() -> void:
	PlayerManager.player.add_sword_ability(self)
	
func activate_ability() -> void:
	if can_activate:
		PlayerManager.player.set_sword_cd(sword_cd_reduction)
	else:
		PlayerManager.player.set_sword_cd(-sword_cd_reduction)

func update_ability(amount = 0) -> void:
	sword_cd_reduction += 0.1

func get_tooltip() -> String:
	return "Sword Cooldown: " + str(PlayerManager.player.stats.base_sword_cooldown - sword_cd_reduction) + " seconds"
