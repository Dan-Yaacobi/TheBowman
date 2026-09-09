class_name FrostBreath extends Node2D

@onready var frost_breath_effect: CPUParticles2D = $FrostBreathEffect
@onready var collision_shape: CollisionShape2D = $HurtBox/CollisionShape2D
@onready var hurt_box: HurtBox = $HurtBox

@export var maximum_length: float = 500
@export var hitbox_max_length: float = 250
@export var hitbox_growth_speed: float = 1.0
@export var beam_width: float = 30.0
@export var tick_interval: float = 0.25
@export var tick_damage: int = 2
@export var slow_duration: float = 1.0

var active: bool = false
var _hit_targets: Array[GameEntity] = []
var _tick_timer: float = 0.0

const FROST_BITE_DEBUFF = preload("uid://d56gf1x11e6x")

func _ready() -> void:
	hurt_box.area_entered.connect(_on_area_entered)
	hurt_box.area_exited.connect(_on_area_exited)
	hurt_box.damage = tick_damage
	collision_shape.shape.size = Vector2.ZERO
	hurt_box.add_effect(apply_slow)
	
func _on_area_entered(a: Area2D) -> void:
	if a.get_parent() is GameEntity:
		var entity: GameEntity = a.get_parent()
		if entity not in _hit_targets:
			_hit_targets.append(entity)

func _on_area_exited(a: Area2D) -> void:
	if a.get_parent() is GameEntity:
		_hit_targets.erase(a.get_parent())

func _process(delta: float) -> void:
	if active:
		frost_breath_effect.emitting = true
		var power: float = PlayerManager.player.get_curr_shot_power()
		handle_breath(calc_direction(), power, delta)
		_tick_damage(delta)
		if power <= 0:
			queue_free()
	else:
		frost_breath_effect.emitting = false

func _tick_damage(delta: float) -> void:
	if _hit_targets.is_empty():
		return
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		for entity in _hit_targets:
			if is_instance_valid(entity):
				entity.take_damage(hurt_box)
				entity.show_damage(hurt_box.damage,Color.AQUA)
				apply_slow(entity)
				
func handle_breath(_direction: Vector2, shot_power: float, delta: float) -> void:
	var dir: Vector2 = _direction.normalized()
	rotation = dir.angle()

	var eased_power: float = 1.0 - pow(1.0 - shot_power, 2.0)
	frost_breath_effect.gravity = Vector2.RIGHT * maximum_length * eased_power

	var target_length: float = hitbox_max_length * eased_power
	var rect: RectangleShape2D = collision_shape.shape
	rect.size.x = lerpf(rect.size.x, target_length, hitbox_growth_speed * delta)
	rect.size.y = beam_width
	collision_shape.position.x = rect.size.x / 2.0

func calc_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var player_pos = PlayerManager.player.global_position
	return Vector2(mouse_pos[0] - player_pos[0], mouse_pos[1] - player_pos[1])

func apply_slow(entity: GameEntity) -> void:
	var frostbite_debuff: FrostBiteDebuff = FROST_BITE_DEBUFF.instantiate()
	entity.apply_debuff(frostbite_debuff,slow_duration,1)
