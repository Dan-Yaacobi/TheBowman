class_name PedestalNPC extends NPC

signal picked(PedestalNPC)

@onready var item_sprite: Sprite2D = $ItemSprite

@onready var top_float_marker: Marker2D = $TopFloatMarker
@onready var bottom_float_marker: Marker2D = $BottomFloatMarker
@onready var item_position: Marker2D = $ItemPosition

@export var item_data: EquipmentData
@onready var gone: NPCGoneState = $NpcStateMachine/Gone

@export var float_duration: float = 2.0
var _float_tween: Tween
var item: Equipment

func extra_ready_functions() -> void:
	if item_data:
		_setup_item_visual()

func set_item(data: EquipmentData) -> void:
	item_data = data
	_setup_item_visual()

func _setup_item_visual() -> void:
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
	picked.emit(self)
	
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

func disable() -> void:
	npc_state_machine.ChangeState(gone)
	item_sprite.queue_free()
	item_data = null
	action_taken = true
