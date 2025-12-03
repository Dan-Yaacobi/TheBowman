class_name DebuffHandler extends Node

signal debuff_added

var debuffs: Dictionary[int,Debuff] = {}
var enemy: Enemy

func set_enemy(_enemy: Enemy) -> void:
	enemy = _enemy
	
func add_debuff(_debuff: Debuff, _duration: float, _ticks: int) -> void:
	var curr_debuff: Debuff
	
	if debuffs.has(_debuff.ID):
		curr_debuff = debuffs[_debuff.ID]
		curr_debuff.ticks += _ticks
	else:
		debuffs[_debuff.ID] = _debuff
		curr_debuff = _debuff
		curr_debuff.debuff_over.connect(remove_debuff)
		curr_debuff.tick_interval = _duration / _ticks
		curr_debuff.enemy = enemy
		debuff_added.emit()

		curr_debuff.ticks = _ticks
		enemy.add_child(curr_debuff)
	


func remove_debuff(_id: int) -> void:
	debuffs.erase(_id)
	
