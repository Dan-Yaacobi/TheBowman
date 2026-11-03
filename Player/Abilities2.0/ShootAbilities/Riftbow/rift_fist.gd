class_name RiftFist extends Node2D
## A demonic fist that flies out of a Riftbow portal and punches the first enemy it reaches with huge knockback.

const FIST_PATH: String = "res://Player/Abilities2.0/ShootAbilities/Riftbow/Sprites/DemonFist.png"
const ENEMY_MASK: int = 28

@export var speed: float = 320.0
@export var max_distance: float = 140.0
@export var hit_radius: float = 9.0

var damage: int = 1
var knockback: float = 400.0
var direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _done: bool = false
var _hurt_box: HurtBox

func _ready() -> void:
	z_index = 3
	rotation = direction.angle()
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(FIST_PATH)
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	_hurt_box = HurtBox.new()
	_hurt_box.collision_layer = 0
	_hurt_box.collision_mask = ENEMY_MASK
	_hurt_box.base_damage = damage
	_hurt_box.knockback_power = knockback
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = hit_radius
	shape.shape = circle
	shape.position = Vector2(10, 0)
	_hurt_box.add_child(shape)
	add_child(_hurt_box)
	# Punch along the travel direction, not away from the fist's centre.
	_hurt_box.add_before_effect(func(_entity: Node, _hb: HurtBox) -> void: _hurt_box.knockback_dir = direction)
	_hurt_box.successful_hit.connect(_on_hit)

func _physics_process(delta: float) -> void:
	if _done:
		return
	var step: float = speed * delta
	global_position += direction * step
	_travelled += step
	if _travelled >= max_distance:
		_finish()

func _on_hit(_hb: HurtBox, _hit: Area2D, _result: DamageResult) -> void:
	EventBus.camera_shake.emit(1.0, 8.0)
	_finish()

func _finish() -> void:
	if _done:
		return
	_done = true
	_hurt_box.set_deferred("monitoring", false)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
