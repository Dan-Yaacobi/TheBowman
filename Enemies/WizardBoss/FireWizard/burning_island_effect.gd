class_name BurningIslandEffect extends Node2D

@onready var hurt_box: HurtBox = $HurtBox
@onready var fire: ColorRect = $Fire
@export var burn_duration: float = 5.0
@export var burn_damage: int = 1
@export var burn_ticks: int = 5
## Seconds between hits while the player stands in the fire
@export var tick_interval: float = 0.5
## How long the fire lasts; 0 = forever
@export var field_lifetime: float = 4.0
## Seconds for the fire to grow from a flat line to full height
@export var grow_time: float = 0.4
## Seconds for the fire to die down at the end of its lifetime
@export var fade_time: float = 0.6

const BURN_DEBUFF = preload("uid://caiebherwxilx")

var _tick_timer: float = 0.0
var _life: float = 0.0
var _fire_material: ShaderMaterial

func _ready() -> void:
	hurt_box.base_damage = burn_damage
	#hurt_box.add_after_effect(apply_burn)
	_fire_material = fire.material as ShaderMaterial
	_set_burn(0.0)

func _physics_process(delta: float) -> void:
	_life += delta
	_update_burn_amount()
	if field_lifetime > 0.0 and _life >= field_lifetime:
		queue_free()
		return
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_retrigger()

func _update_burn_amount() -> void:
	var amount: float = 1.0
	if grow_time > 0.0:
		amount = minf(amount, _life / grow_time)
	if field_lifetime > 0.0 and fade_time > 0.0:
		amount = minf(amount, (field_lifetime - _life) / fade_time)
	_set_burn(clampf(amount, 0.0, 1.0))

func _set_burn(value: float) -> void:
	if _fire_material:
		_fire_material.set_shader_parameter("burn_amount", value)

# Toggling monitoring makes anything still inside register as entering again
func _retrigger() -> void:
	hurt_box.monitoring = false
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	hurt_box.monitoring = true

func apply_burn(_target: GameEntity, _parent, _result) -> void:
	if _target is Player:
		var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
		burn_debuff.set_damage(burn_damage)
		_target.apply_debuff(burn_debuff, CustomVariables.BURN_DEBUFF_ID, burn_duration, burn_ticks)
