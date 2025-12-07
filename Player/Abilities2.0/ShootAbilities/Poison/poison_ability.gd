class_name PoisonHitAbility extends PlayerShootAbility

var poison_chance: int = 5

func add_ability() -> void:
	PlayerManager.player.add_shoot_ability(self)

func activate_ability() -> void:
	if can_activate and arrow:
		arrow.poison_chance += poison_chance

func update_ability(_amount = 0) -> void:
	poison_chance += randi_range(1,4)

func get_tooltip() -> String:
	return "Poison Chance: " + str(poison_chance) + "%"
