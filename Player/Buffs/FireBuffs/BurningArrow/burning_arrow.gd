class_name BurningArrow extends Buff
## Makes your next arrow burn with % chance

@export_range(0,100,1,"suffix:%") var chance: int = 50
const BURN = preload("res://Player/Effects/OnHitEffects/Resources/burn.tres")

func start_buff_effect() -> void:
	tooltip = str(chance) + "% Your Next Arrow Will Burn The Enemy" 
	PlayerManager.player.add_hit_effect(BURN, 1)

func check_end_conditions() -> bool:
	if time_accumulator >= duration:
		return true
	return false

func extra_end_buff_methods() -> void:
	PlayerManager.player.remove_hit_effect(BURN)
