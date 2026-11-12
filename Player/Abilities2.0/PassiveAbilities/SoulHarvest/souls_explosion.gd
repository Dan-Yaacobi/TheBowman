class_name SoulExplosion extends Node2D

const SOUL = preload("uid://3kavoouowc45")

var souls_amount: int
## The bow's color bonus, passed on to every soul.
var damage_mult: float = 1.0

func _ready() -> void:
	summon_souls(souls_amount)
	
func setup(_amount: int) -> void:
	souls_amount = _amount
	
func summon_souls(_amount: int) -> void:
	for i: int in _amount:
		var soul: Soul = SOUL.instantiate()
		soul.damage_mult = damage_mult
		add_child(soul)
		soul.global_position = global_position
		soul.set_spiral((TAU / _amount) * i)
	pass
