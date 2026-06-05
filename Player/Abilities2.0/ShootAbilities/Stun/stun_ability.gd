class_name StunAbility extends PlayerShootAbility

var stun_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func update_ability(_amount = 0) -> void:
	stun_chance+= randi_range(1,4)

func get_tooltip() -> String:
	return "Stun Chance: " + str(stun_chance) + "%"
