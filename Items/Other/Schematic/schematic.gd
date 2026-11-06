class_name Schematic extends Item
## Unidentified schematic pickup. The spirit reveals which recipe it is back in the hub.
## Spawned by Crafting.try_drop_schematic().
## On pickup it rises above the player's head, shines for a moment, then zooms into them.

@export var bob_speed: float = 2.0
@export var bob_height: float = 3.0

@export_group("Claim")
## Where it hovers, relative to the player's origin.
@export var hover_offset: Vector2 = Vector2(0, -34)
@export var rise_duration: float = 0.35
@export var hover_duration: float = 0.9
@export var zoom_duration: float = 0.18
## Sprite scale multiplier while hovering.
@export var hover_scale: float = 1.6
## Peak brightness of the shine pulses (values above 1 brighten).
@export var shine_color: Color = Color(1.8, 1.7, 1.3)
@export var shine_pulses: int = 2
@export_group("")

@onready var sprite: Sprite2D = $Sprite2D

var _bob_time: float = 0.0
var _claiming: bool = false
var _claim_start: Vector2 = Vector2.ZERO
## 0 → 1 while rising from the pickup spot to above the head.
var _rise_weight: float = 0.0
## 0 → 1 while zooming from above the head into the player.
var _zoom_weight: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

## Pops up and settles back in place, like the color scroll.
func launch(_target: Vector2) -> void:
	_landed = false
	var origin: Vector2 = global_position
	_tween = create_tween()
	var mid: Vector2 = origin + Vector2(0, -arc_height)
	_tween.tween_method(_move_along_arc.bind(origin, mid, origin), 0.0, 1.0, arc_duration)
	_tween.tween_callback(_on_arc_complete)

func _process(delta: float) -> void:
	if not _claiming:
		super(delta)
		return
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	_bob_time += delta
	var hover_point: Vector2 = _player.global_position + hover_offset + Vector2(0, sin(_bob_time * bob_speed * 2.0) * 1.5)
	var risen: Vector2 = _claim_start.lerp(hover_point, ease(_rise_weight, -2.0))
	global_position = risen.lerp(_player.global_position, ease(_zoom_weight, 2.0))

func extra_process_functions(delta: float) -> void:
	_bob_time += delta
	position.y += sin(_bob_time * bob_speed) * bob_height * delta

## Rare, so it never despawns off-screen.
func initiate_despawn() -> void:
	pass

## Saved right away, so dying mid-animation can't lose it. The rest is visual.
func _collect() -> void:
	if _claiming:
		return
	_claiming = true
	Crafting.add_schematic()
	lifetime_timer.stop()
	if _tween:
		_tween.kill()
	_claim_start = global_position
	_base_scale = sprite.scale
	_play_claim()

func _play_claim() -> void:
	var tween: Tween = create_tween()
	# Rise above the head and grow.
	tween.set_parallel(true)
	tween.tween_property(self, "_rise_weight", 1.0, rise_duration)
	tween.tween_property(sprite, "scale", _base_scale * hover_scale, rise_duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void: CombatTextSpawner.spawn(global_position + Vector2(0, -12), text, color))
	# Shine.
	var pulse: float = hover_duration / float(maxi(shine_pulses, 1) * 2)
	for i: int in shine_pulses:
		tween.tween_property(sprite, "modulate", shine_color, pulse).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "modulate", Color.WHITE, pulse).set_trans(Tween.TRANS_SINE)
	# Zoom into the player.
	tween.set_parallel(true)
	tween.tween_property(self, "_zoom_weight", 1.0, zoom_duration)
	tween.tween_property(sprite, "scale", Vector2.ZERO, zoom_duration).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
