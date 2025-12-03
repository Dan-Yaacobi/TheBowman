class_name StunAbility extends PlayerShootAbility

var stun_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability() -> void:
	if activated and arrow:
		arrow.stun_chance += stun_chance

func update_ability() -> void:
	stun_chance+= randi_range(1,4)

func get_tooltip() -> String:
	return "Stun Chance: " + str(stun_chance) + "%"
