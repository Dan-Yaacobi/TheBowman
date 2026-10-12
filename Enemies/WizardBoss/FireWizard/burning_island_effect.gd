class_name BurningIslandEffect extends Node2D

@onready var hurt_box: HurtBox = $HurtBox
@export var burn_duration: float = 5.0
@export var burn_damage: int = 1
@export var burn_ticks: int = 5
## Seconds between hits while the player stands in the fire
@export var tick_interval: float = 0.5
## How long the fire lasts; 0 = forever
@export var field_lifetime: float = 4.0

const BURN_DEBUFF = preload("uid://caiebherwxilx")

var _tick_timer: float = 0.0
var _life: float = 0.0

func _ready() -> void:
	hurt_box.base_damage = burn_damage
	hurt_box.add_after_effect(apply_burn)

func _physics_process(delta: float) -> void:
	if field_lifetime > 0.0:
		_life += delta
		if _life >= field_lifetime:
			queue_free()
			return
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_retrigger()

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
