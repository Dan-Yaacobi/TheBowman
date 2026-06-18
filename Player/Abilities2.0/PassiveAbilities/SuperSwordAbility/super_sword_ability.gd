class_name SuperSwordAbility extends PlayerPassiveAbility

@export var id_1: int = 996
@export var id_2: int = 995
@export var id_3: int = 994

func on_equipped() -> void:
	PlayerManager.player.stats.sword_damage.add_buff(id_1,1.0,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.sword_size.add_buff(id_2,1.0,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.base_sword_cooldown.add_buff(id_3,0.5,Stat.buff_type.MULTIPLICATIVE)

func on_unequipped() -> void:
	PlayerManager.player.stats.sword_damage.remove_buff_stack(id_1,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.sword_size.remove_buff_stack(id_2,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.base_sword_cooldown.remove_buff_stack(id_3,Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Double sword damage and size and halves its cooldown"
