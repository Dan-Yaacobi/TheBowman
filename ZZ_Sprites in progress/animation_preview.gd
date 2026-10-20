@tool
extends Node
## Editor-only preview for the archer rig.
## Add as a child of the archer node. Plays Body, MainHand and OffHand together.
## Removes itself at runtime, so it never affects the game.

@export var animation: String = "":
	set(value):
		animation = value
		_play()

@export_range(0.0, 3.0, 0.05) var speed: float = 1.0:
	set(value):
		speed = value
		for sprite: AnimatedSprite2D in _get_sprites():
			sprite.speed_scale = speed

@export var frame: int = 0:
	set(value):
		frame = maxi(value, 0)
		_scrub(frame)

@export_tool_button("Play", "Play") var play_button: Callable = _play
@export_tool_button("Pause", "Pause") var pause_button: Callable = _pause
@export_tool_button("Stop", "Stop") var stop_button: Callable = _stop
@export_tool_button("Refresh Animations", "Reload") var refresh_button: Callable = notify_property_list_changed

const SPRITE_NAMES: Array[StringName] = [&"Body", &"MainHand", &"OffHand"]


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()
		return
	notify_property_list_changed()


func _validate_property(property: Dictionary) -> void:
	if property.name != "animation":
		return
	var body: AnimatedSprite2D = _get_sprite(&"Body")
	if body == null or body.sprite_frames == null:
		return
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(body.sprite_frames.get_animation_names())


func _play() -> void:
	if animation.is_empty():
		return
	for sprite: AnimatedSprite2D in _get_sprites():
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
			sprite.speed_scale = speed
			sprite.play(animation)
			sprite.set_frame_and_progress(0, 0.0)
		else:
			sprite.stop()


func _pause() -> void:
	for sprite: AnimatedSprite2D in _get_sprites():
		sprite.pause()


func _stop() -> void:
	for sprite: AnimatedSprite2D in _get_sprites():
		sprite.stop()
		sprite.frame = 0


func _scrub(target_frame: int) -> void:
	if animation.is_empty():
		return
	for sprite: AnimatedSprite2D in _get_sprites():
		if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(animation):
			continue
		sprite.animation = animation
		sprite.pause()
		var last_frame: int = sprite.sprite_frames.get_frame_count(animation) - 1
		sprite.frame = mini(target_frame, last_frame)


func _get_sprites() -> Array[AnimatedSprite2D]:
	var sprites: Array[AnimatedSprite2D] = []
	for sprite_name: StringName in SPRITE_NAMES:
		var sprite: AnimatedSprite2D = _get_sprite(sprite_name)
		if sprite:
			sprites.append(sprite)
	return sprites


func _get_sprite(sprite_name: StringName) -> AnimatedSprite2D:
	var rig: Node = get_parent()
	if rig == null:
		return null
	return rig.get_node_or_null(NodePath(sprite_name)) as AnimatedSprite2D
