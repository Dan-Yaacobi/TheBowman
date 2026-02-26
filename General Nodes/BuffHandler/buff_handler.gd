class_name BuffHandler extends Node2D

signal buff_added

var buffs: Dictionary[int,Buff] = {}
var entity: Node2D

func set_entity(_entity: Node2D) -> void:
	entity = _entity
	if entity is Player:
		EventBus.add_player_buff.connect(add_buff)
	
func add_buff(_buff: Buff) -> void:
	if buffs.has(_buff.ID):
		var curr_buff: Buff = buffs[_buff.ID]
		curr_buff.add_stack()
		if !curr_buff.constant_buff:
			curr_buff.ticks += _buff.ticks
	else:
		buffs[_buff.ID] = _buff
		_buff.buff_over.connect(remove_buff)
		_buff.entity = entity
		buff_added.emit(_buff)
		entity.add_child(_buff)
	
func remove_buff(_id: int) -> void:
	print("buff over with id: ", _id)
	EventBus.player_buff_ended.emit(_id)
	buffs.erase(_id)
