class_name Upgrades extends Node2D

@onready var player: Player = $".."

var upgrades_dict: Dictionary = {"hp": "upgrade_hp","jumps": "upgrade_jumps", 
"knockback resistance": "upgrade_knockback_resistance","move speed": "upgrade_movement_speed"}

var new_abilities_dict: Dictionary = {"jumps": "add_jumping_ability", "shooting": "add_shooting_ability", 
"arrow":"add_arrow_ability", "slam": "add_slam_ability"}

func upgrade_hp(amount: int) -> void:
	player.stats.max_hp += amount
	player.stats.hp = player.stats.max_hp
	player.health_bar.init_health(player.stats.max_hp)

func upgrade_jumps(amount: int) -> void:
	player.stats.max_jumps += amount
	player.jump_action.jumps = player.stats.max_jumps
	
func upgrade_knockback_resistance(amount: int) -> void:
	player.stats.knockback_resistance += amount

func upgrade_movement_speed(amount: int) -> void:
	player.stats.move_speed += amount
	
func add_shooting_ability(ability: ShootAbility) -> void:
	if ability != null:
		if ability is ShootAbility:
			player.stats.shoot_abilities.append(ability)

func add_jumping_ability(ability: JumpAbility) -> void:
	if ability != null:
		if ability is JumpAbility:
			player.stats.jump_abilities.append(ability)
		
func add_arrow_ability(ability: ArrowAbility) -> void:
	if ability != null:
		if ability is ArrowAbility:
			player.stats.arrow_abilities.append(ability)
			
func add_slam_ability(ability: SlamAbility) -> void:
	if ability != null:
		if ability is SlamAbility:
			player.stats.slam_abilities.append(ability)
		
