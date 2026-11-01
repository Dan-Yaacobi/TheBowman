class_name HellfireNova extends Node2D
## A one-shot ring of fire. The moment it goes off it hurts everything inside `radius`,
## knocks them outward and sets them burning, then plays its animation and frees itself.

@export var damage: int = 2
@export var knockback: float = 300.0
## Seconds for the hit area to grow from the centre to the full radius, in step with the ring art
@export var expand_time: float = 0.25
## Seconds the hit stays active once it has reached full size
@export var hit_window: float = 0.05
@export_group("Burn")
@export var burn_scene: PackedScene
@export var burn_damage: int = 1
@export var burn_duration: float = 3.0
@export var burn_ticks: int = 3
@export_group("Animation")
@export var fps: float = 16.0
@export var frame_count: int = 10
## Radius of the fire ring at its widest in the sprite art, in pixels.
## The sprite is scaled so the ring matches the blast radius.
@export var art_radius: float = 58.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_shape: CollisionShape2D = $HurtBox/CollisionShape2D

var _playing: bool = false
var _anim_time: float = 0.0
var _radius: float = 80.0
var _hitting: bool = false

func _ready() -> void:
	hurt_box.base_damage = damage
	hurt_box.knockback_power = knockback
	hurt_box.add_after_effect(_apply_burn)
	hurt_box.monitoring = false
	sprite.visible = false

## Go off at `at` with the given radius (pixels)
func blast(radius: float, at: Vector2) -> void:
	if not is_node_ready():
		await ready
	global_position = at
	_radius = radius
	_set_hit_radius(0.0)
	sprite.scale = Vector2.ONE * (radius / maxf(art_radius, 1.0))
	sprite.frame = 0
	sprite.visible = true
	_anim_time = 0.0
	_playing = true
	_hitting = true
	hurt_box.set_deferred("monitoring", true)

func _process(delta: float) -> void:
	if not _playing:
		return
	_anim_time += delta
	if _hitting:
		# The hit area grows outward with the ring, so it lands when the flames reach you
		var grow: float = clampf(_anim_time / maxf(expand_time, 0.01), 0.0, 1.0)
		_set_hit_radius(grow)
		if _anim_time >= expand_time + hit_window:
			_hitting = false
			hurt_box.set_deferred("monitoring", false)
	var frame: int = int(_anim_time * fps)
	if frame >= frame_count:
		_playing = false
		queue_free()
		return
	sprite.frame = frame

func _set_hit_radius(grow: float) -> void:
	var circle: CircleShape2D = hit_shape.shape as CircleShape2D
	if circle:
		circle.radius = maxf(_radius * grow, 1.0)

func _apply_burn(target: GameEntity, _hurt_box: Node2D, _result: DamageResult) -> void:
	if burn_scene == null or not target is Player:
		return
	var burn: BurnDebuff = burn_scene.instantiate()
	burn.set_damage(burn_damage)
	target.apply_debuff(burn, CustomVariables.BURN_DEBUFF_ID, burn_duration, burn_ticks)
