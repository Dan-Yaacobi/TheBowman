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
	hurt_box.add_effect(_effect)
	burn_timer.timeout.connect(queue_free)
	burn_timer.start()
