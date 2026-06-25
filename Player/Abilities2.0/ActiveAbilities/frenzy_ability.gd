class_name FrenzyAbility extends ActiveAbility

const FRENZY_BUFF = preload("uid://boplqco7dofd")

func activate(_player: Player) -> void:
	var buff: FrenzyBuff = FRENZY_BUFF.instantiate()
	EventBus.add_player_buff.emit(buff)
