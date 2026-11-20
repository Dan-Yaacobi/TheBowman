class_name MenuTarget extends Sprite2D
## Something in the title-screen scenery that an arrow can hit.
## By default the arrow sticks in it and fades; subclasses react in their own way.

## False: arrows pass through (clouds) and only trigger on_passed_through().
@export var stops_arrow: bool = true
## Seconds an arrow stays stuck before fading.
@export var arrow_linger: float = 4.0
## Played on a hit, on top of the arrow's own thunk.
@export var hit_sound: AudioStream
@export var hit_sound_db: float = -6.0

## True if `point` (in global canvas coordinates) lands on an opaque pixel.
func covers(point: Vector2) -> bool:
	return is_visible_in_tree() and is_pixel_opaque(to_local(point))

## Depth of the layer this target lives in (0 = horizon, 1 = viewer).
func get_depth() -> float:
	var node: Node = get_parent()
	while node:
		if node is MenuLayer:
			return (node as MenuLayer).depth
		node = node.get_parent()
	return 0.5

## The arrow just landed at `local_point`. Owns the arrow from here on.
func react(arrow: MenuArrow, _local_point: Vector2) -> void:
	arrow.stick(self, arrow_linger)

## An arrow flew through this target on its way somewhere else.
func on_passed_through(_local_point: Vector2) -> void:
	pass

func play_hit_sound() -> void:
	play_sound(hit_sound)

func play_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = hit_sound_db
	player.pitch_scale = randf_range(0.92, 1.08)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

## Brief white-hot flash, like a hit enemy.
func flash(strength: float = 2.2, time: float = 0.18) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "self_modulate", Color(strength, strength, strength), 0.03)
	tween.tween_property(self, "self_modulate", Color.WHITE, time)
