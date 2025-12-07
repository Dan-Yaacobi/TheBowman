class_name SlashHurtBox extends HurtBox

var bleed_chance: int = 0
var sword: Sword
const BLEED_DEBUFF = preload("res://Debuffs/Bleed/BleedDebuff.tscn")

func set_sword(_sword: Sword) -> void:
	sword = _sword
	
func added_effects(a: Enemy) -> void:
	apply_bleed(a)
	
func apply_bleed(a: Enemy) -> void:
	var try_bleed: int = randi_range(1,100)
	if try_bleed < sword.get_bleed_chance():
		var new_bleed_debuff: BleedDebuff = BLEED_DEBUFF.instantiate()
		new_bleed_debuff.set_damage(max(floor(PlayerManager.player.get_strength() / 10),1))
		a.apply_debuff(new_bleed_debuff,5,5)

	pass
