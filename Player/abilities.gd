class_name AbilitiesContoller extends Node2D

@onready var shoot_abilities: Node2D = $ShootAbilities
@onready var periodic_abilities: Node2D = $PeriodicAbilities
@onready var active_abilities: Node2D = $ActiveAbilities

func add_shoot_ability(_ability: PlayerShootAbility) -> void:
	if _ability:
		PlayerManager.player.stats.shoot_abilities.append(_ability)
	pass
