class_name PedestalNPC extends NPC

@onready var item_sprite: Sprite2D = $ItemSprite

@onready var top_float_marker: Marker2D = $TopFloatMarker
@onready var bottom_float_marker: Marker2D = $BottomFloatMarker
@onready var item_position: Marker2D = $ItemPosition

@export var item_data: EquipmentData

@export var float_duration: float = 2.0
var _float_tween: Tween
var item: Equipment

func extra_ready_functions() -> void:
	if item_data:
		item_sprite.texture = item_data.texture
		item_sprite.scale *= item_data.dropped_scale
		item_sprite.position = item_position.position
		_start_float()

func action(_index: int) -> void:
	match _index:
		0:
			_get_item()

func _get_item() -> void:
	EventBus.drop_specific_item.emit(item_data, item_position.global_position)
	action_taken = true
	
func _start_float() -> void:
	_float_tween = create_tween()
	_float_tween.set_loops()
	_float_tween.set_trans(Tween.TRANS_SINE)
	_float_tween.set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(item_sprite, "global_position", bottom_float_marker.global_position, float_duration)
	_float_tween.tween_property(item_sprite, "global_position", top_float_marker.global_position, float_duration)

func extra_gone_function() -> void:
	item_sprite.queue_free()
	_float_tween.kill()
