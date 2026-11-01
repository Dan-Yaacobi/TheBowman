class_name ColorScroll extends Item
## Pickup that lets the player raise one color level (choice happens in ColorScrollPicker).
## Spawn with EventBus.drop_item.emit(CustomVariables.items.COLOR_SCROLL, position, 100.0, 1)
## or an ItemReward set to COLOR_SCROLL.

## Cycled on the pickup to show it can become any color.
@export var textures: Array[Texture2D] = []
@export var cycle_interval: float = 0.5
@export var bob_speed: float = 2.0
@export var bob_height: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D

var _bob_time: float = 0.0
var _cycle_time: float = 0.0
var _texture_index: int = 0

func extra_ready_functions() -> void:
	if not textures.is_empty():
		sprite.texture = textures[0]

## Pops up and settles back in place, like the potion.
func launch(_target: Vector2) -> void:
	_landed = false
	var origin: Vector2 = global_position
	_tween = create_tween()
	var mid: Vector2 = (origin + _target) / 2.0 + Vector2(0, -arc_height)
	_tween.tween_method(_move_along_arc.bind(origin, mid, origin), 0.0, 1.0, arc_duration)
	_tween.tween_callback(_on_arc_complete)

func extra_process_functions(delta: float) -> void:
	_bob_time += delta
	position.y += sin(_bob_time * bob_speed) * bob_height * delta
	if textures.size() > 1:
		_cycle_time += delta
		if _cycle_time >= cycle_interval:
			_cycle_time -= cycle_interval
			_texture_index = (_texture_index + 1) % textures.size()
			sprite.texture = textures[_texture_index]

## Scrolls are rare rewards, so they never despawn off-screen.
func initiate_despawn() -> void:
	pass

func _collect() -> void:
	EventBus.color_scroll_collected.emit()
	queue_free()
