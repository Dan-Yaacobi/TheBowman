class_name DebuffHandler extends Node

signal debuff_added

var debuffs: Dictionary[int,Debuff] = {}
var entity: GameEntity

func set_entity(_entity: GameEntity) -> void:
	entity = _entity
	
func add_debuff(_debuff: Debuff, ID: int, _duration: float, _ticks: int) -> void:
	if debuffs.has(ID):
		if _debuff.can_stack:
			debuffs[ID].merge(_debuff, _ticks)
		_debuff.queue_free()
		return

	debuffs[ID] = _debuff
	_debuff.ID = ID
	_debuff.debuff_over.connect(remove_debuff)
	_debuff.tick_interval = _duration / _ticks
	_debuff.entity = entity
	_debuff.ticks = _ticks
	debuff_added.emit()
	entity.sprite.add_child(_debuff)

func has_debuff(id: int) -> bool:
	return debuffs.has(id)

func end_debuff(id: int) -> void:
	if has_debuff(id):
		debuffs[id].debuff_end()
		
func reset_debuffs() -> void:
	for debuff: Debuff in debuffs.values():
		debuff.debuff_end()
		
func remove_debuff(_id: int) -> void:
	debuffs.erase(_id)
	
