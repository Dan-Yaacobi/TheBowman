class_name Debuff extends Node2D

signal debuff_over(id: int)

@export var ID: int

var time_accumulator: float
var tick_interval: float
var ticks: int = 0
var one_shot: bool = false
var enemy: Enemy

func _ready() -> void:
	start_debuff_effect()
	
func apply_debuff_effect() -> void:
	pass

func start_debuff_effect() -> void:
	pass
	
func _process(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= tick_interval:
		time_accumulator -= tick_interval
		if not one_shot:
			apply_debuff_effect()
		ticks -= 1
		if ticks <= 0:
			debuff_end()
			
func debuff_end() -> void:
	debuff_over.emit(ID)
	extra_end_debuff_methods()
	queue_free()

func extra_end_debuff_methods() -> void:
	pass
