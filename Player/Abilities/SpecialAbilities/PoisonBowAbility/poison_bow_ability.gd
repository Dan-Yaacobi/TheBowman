class_name PoisonBowAbility extends SpecialAbility

const POISON_CLOUD = preload("res://Player/Abilities/SpecialAbilities/PoisonBowAbility/PoisonCloud.tscn")

func activate_special_ability(_player: Player) -> void:
	var poison_cloud = POISON_CLOUD.instantiate()
	poison_cloud.global_position = _player.global_position
	_player.get_parent().call_deferred("add_child",poison_cloud)
	poison_cloud.emitting = true
	pass
