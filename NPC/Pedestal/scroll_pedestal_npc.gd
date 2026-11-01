class_name ScrollPedestalNPC extends NPC
## Pedestal holding a color scroll, placed by the RiftGenerator.
## Interacting takes the scroll and opens the ColorScrollPicker.

## Cycled on the floating scroll to show it can become any color.
@export var scroll_textures: Array[Texture2D] = []
@export var cycle_interval: float = 0.5
@export var float_duration: float = 2.0

@onready var item_sprite: Sprite2D = $ItemSprite
@onready var top_float_marker: Marker2D = $TopFloatMarker
@onready var bottom_float_marker: Marker2D = $BottomFloatMarker

var _float_tween: Tween
var _cycle_time: float = 0.0
var _texture_index: int = 0

func extra_ready_functions() -> void:
	if not scroll_textures.is_empty():
		item_sprite.texture = scroll_textures[0]
	_start_float()

func extra_process_function(delta: float) -> void:
	if action_taken or scroll_textures.size() < 2:
		return
	_cycle_time += delta
	if _cycle_time >= cycle_interval:
		_cycle_time -= cycle_interval
		_texture_index = (_texture_index + 1) % scroll_textures.size()
		item_sprite.texture = scroll_textures[_texture_index]

func action(_index: int) -> void:
	if action_taken:
		return
	action_taken = true
	EventBus.color_scroll_collected.emit()

## Local positions so the float follows the island this pedestal sits on.
func _start_float() -> void:
	if _float_tween:
		_float_tween.kill()
	_float_tween = create_tween()
	_float_tween.set_loops()
	_float_tween.set_trans(Tween.TRANS_SINE)
	_float_tween.set_ease(Tween.EASE_IN_OUT)
	_float_tween.tween_property(item_sprite, "position", bottom_float_marker.position, float_duration)
	_float_tween.tween_property(item_sprite, "position", top_float_marker.position, float_duration)

func extra_gone_function() -> void:
	if _float_tween:
		_float_tween.kill()
	item_sprite.hide()
