class_name BoneBowAbility extends SpecialAbility

const SKELETON = preload("res://Player/Abilities/SpecialAbilities/BoneBowAbility/Skeleton/Skeleton.tscn")

func can_use(_player: Player) -> bool:
	return _player.velocity.y == 0 and _player.can_summon() and _player.get_parent() is PlayGround

func activate_special_ability(_player: Player) -> void:
	if can_use(_player):
		var new_skeleton: Skeleton = SKELETON.instantiate()
		new_skeleton.global_position = _player.global_position
		_player.get_parent().call_deferred("add_child", new_skeleton)
		_player.current_minions.append(new_skeleton)
