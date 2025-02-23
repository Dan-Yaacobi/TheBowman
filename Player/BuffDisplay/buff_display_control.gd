class_name TotalBuffs extends Control

@onready var flow_container: FlowContainer = $FlowContainer
@onready var buff_ids: Dictionary = {}
@onready var player: Player = $".."

const BUFF = preload("res://Player/BuffDisplay/Buff.tscn")

func add_display_buff(buff_node: PlayerUpgrade) -> void:
	if not buff_ids.has(buff_node.ID):
		var new_buff: Buff = BUFF.instantiate()
		new_buff.set_buff(buff_node.normal_texture,buff_node.ID,buff_node.get_buff_tooltip(player))
		buff_ids[buff_node.ID] = new_buff
		flow_container.add_child(new_buff)
	else:
		buff_ids[buff_node.ID].add_buff(1,buff_node,player)
		

func clear_buffs() -> void:
	buff_ids = {}
	for child in flow_container.get_children():
		child.queue_free()
