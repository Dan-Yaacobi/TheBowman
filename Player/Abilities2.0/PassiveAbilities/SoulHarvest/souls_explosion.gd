class_name SoulExplosion extends Node2D

const SOUL = preload("uid://3kavoouowc45")

var souls_amount: int

func _ready() -> void:
	summon_souls(souls_amount)
	
func setup(_amount: int) -> void:
	souls_amount = _amount
	
func summon_souls(_amount: int) -> void:
	for i: int in _amount:
		var soul: Soul = SOUL.instantiate()
		add_child(soul)
		soul.global_position = global_position
		soul.set_spiral((TAU / _amount) * i)
	pass
