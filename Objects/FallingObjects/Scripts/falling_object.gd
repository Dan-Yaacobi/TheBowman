class_name FallingObject extends RigidBody2D

const ITEM_PICK_UP = preload("res://Items/ItemPickUp.tscn")

signal damaged

@export var data: FallingObjectData
var player: Player
var destroyed_state: bool = false
	
func set_player(_player: Player) -> void:
	if _player != null:
		player = _player

func take_hit(a) -> void:
	if not destroyed_state:
		if a is Arrow:
			data.hits_to_destory -= 1
			a.clear_shot()
			if data.hits_to_destory <= 0:
				destroyed_state = true
				destroyed()
			else:
				damaged.emit()
			
func destroyed() -> void:
	queue_free()
	
func spawn_drop(drop) -> void:
	var item = ITEM_PICK_UP.instantiate()
	item.assign_item(drop.item_data)
	item.global_position = global_position
	item.inititalize(player)
	get_parent().call_deferred("add_child", item)
