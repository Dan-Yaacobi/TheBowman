class_name BasicBowAbility extends SpecialAbility

const BASIC_BOW_PARTICLES = preload("res://Player/Abilities/SpecialAbilities/basic_bow_ability/basic_bow_particles.tscn")
var push_distance: int = 50

func activate_special_ability(_player: Player) -> void:
	var side: int 
	if _player.direction_side:
		side = -1
	else:
		side = 1
		
	var particles = BASIC_BOW_PARTICLES.instantiate()
	particles.gravity.x *= side * 1
	particles.emitting = true
	_player.add_child(particles)
	_player.velocity.x += side * push_distance
	print("Fart")
