class_name BurnPatch extends Node2D

@onready var burn_timer: Timer = $BurnTimer
@onready var hurt_box: HurtBox = $HurtBox

var _damage: int
var _effect: Callable

func setup(damage: int, effect: Callable) -> void:
	_damage = damage
	_effect = effect

func _ready() -> void:
	hurt_box.base_damage = _damage
	# HurtBox calls after-effects with (target, hurt_box, result); the burn only needs the enemy
	hurt_box.add_after_effect(func(target: GameEntity, _hurt_box: Node2D, _result: DamageResult) -> void:
		if target is Enemy:
			_effect.call(target))
	burn_timer.timeout.connect(queue_free)
	burn_timer.start()
