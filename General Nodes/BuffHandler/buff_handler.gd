class_name BuffHandler extends Node2D

signal buff_added

var buffs: Dictionary[int,Buff] = {}
var entity: Node2D

func set_entity(_entity: Node2D) -> void:
	entity = _entity
	
func add_buff(_buff: Buff, _duration: float, _ticks: int,
 _constant_buff: bool, _total_time: float) -> void:
	
	var curr_buff: Buff
	
	if buffs.has(_buff.ID):
		curr_buff = buffs[_buff.ID]
		curr_buff.ticks += _ticks
	else:
		buffs[_buff.ID] = _buff
		curr_buff = _buff
		curr_buff.constant_buff = _constant_buff
		curr_buff.total_time = _total_time
		curr_buff.debuff_over.connect(remove_buff)
		curr_buff.tick_interval = _duration / _ticks
		curr_buff.entity = entity
		buff_added.emit()

		curr_buff.ticks = _ticks
		entity.add_child(curr_buff)
	

func remove_buff(_id: int) -> void:
	buffs.erase(_id)
	
