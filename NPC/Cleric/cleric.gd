class_name Cleric extends NPC

@export var bless_cost: int = 25

var buying: bool = false

func action(_index: int) -> void:
	match _index:
		0:
			_bless()

func _bless() -> void:
	if not buying:
		buying = true
		if PlayerManager.player.buy(bless_cost):
			PlayerManager.player.increase_max_hp(true)
			show_post_action_line()
			action_taken = true
		buying = false
		
