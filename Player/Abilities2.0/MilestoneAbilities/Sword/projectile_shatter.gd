class_name ProjectileShatter extends Node2D
## Shown where the sword cuts an enemy projectile apart (Parry milestone):
## a bright slash flash, an expanding ring and shards flying off.

const FLASH_COLOR: Color = Color(1.0, 0.97, 0.85)
const SHARD_COLOR: Color = Color(1.0, 0.8, 0.35)
const LIFE: float = 0.3

## Direction of the cut, so the slash line follows the swing.
var cut_direction: Vector2 = Vector2.RIGHT
var _t: float = 0.0

func _ready() -> void:
	z_index = 6
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	_add_shards()
	var tween: Tween = create_tween()
	tween.tween_property(self, "_t", 1.0, LIFE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(0.25)
	tween.tween_callback(queue_free)
	EventBus.camera_shake.emit(1.0, 10.0)
	GeneralFunctions.hit_freeze(0.04)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var fade: float = 1.0 - _t
	if fade <= 0.0:
		return
	# Ring.
	draw_arc(Vector2.ZERO, 4.0 + 16.0 * _t, 0.0, TAU, 20, Color(FLASH_COLOR, fade * 0.9), 2.0 * fade + 0.5)
	# Slash line across the projectile.
	var half: Vector2 = cut_direction.orthogonal() * (14.0 * (0.5 + _t))
	draw_line(-half, half, Color(FLASH_COLOR, fade), 3.0 * fade + 0.5)
	# Center pop.
	draw_circle(Vector2.ZERO, 6.0 * fade, Color(FLASH_COLOR, fade))

func _add_shards() -> void:
	var shards: CPUParticles2D = CPUParticles2D.new()
	shards.one_shot = true
	shards.explosiveness = 1.0
	shards.amount = 12
	shards.lifetime = 0.45
	shards.direction = cut_direction
	shards.spread = 70.0
	shards.gravity = Vector2(0, 300)
	shards.initial_velocity_min = 70.0
	shards.initial_velocity_max = 150.0
	shards.scale_amount_min = 1.5
	shards.scale_amount_max = 3.0
	shards.color = SHARD_COLOR
	shards.emitting = true
	shards.use_parent_material = false
	add_child(shards)
