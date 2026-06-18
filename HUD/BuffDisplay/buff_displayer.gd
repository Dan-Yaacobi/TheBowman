class_name BuffDisplayer extends HFlowContainer

var buffs: Dictionary[int, BuffDisplay]
const BUFF_DISPLAY = preload("res://HUD/BuffDisplay/BuffDisplay.tscn")

func _ready() -> void:
	EventBus.add_player_buff.connect(add_buff)
	EventBus.player_buff_ended.connect(remove_buff)
	for child in get_children():
		child.queue_free()
		
func add_buff(_buff: Buff) -> void:
	if buffs.has(_buff.ID):
		buffs[_buff.ID].add_stack(1,_buff.duration)
		
	else:
		var new_buff_display: BuffDisplay = BUFF_DISPLAY.instantiate()
		new_buff_display.texture = _buff.texture
		new_buff_display.set_duration(_buff.duration)
		new_buff_display.max_stacks = _buff.max_stacks
		new_buff_display.ID = _buff.ID
		new_buff_display.stacks = _buff.stacks
		new_buff_display.constant_buff = _buff.constant_buff
		new_buff_display.tooltip_text = _buff.tooltip
		
		add_child(new_buff_display)
		new_buff_display.buff_ended.connect(remove_buff)
		buffs[_buff.ID] = new_buff_display
		
func remove_buff(_id: int) -> void:
	if buffs.has(_id):
		buffs[_id].queue_free()
		buffs.erase(_id)
