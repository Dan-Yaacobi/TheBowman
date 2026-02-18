class_name Buff extends Node2D

signal buff_over(id: int)

@export var ID: int
@export var texture: Texture
@export var tooltip: String

var constant_buff: bool
var total_time: float

var time_accumulator: float
var tick_interval: float
var ticks: int = 0

var entity: Node2D

func _ready() -> void:
	start_buff_effect()
	
func apply_buff_effect() -> void:
	pass

func start_buff_effect() -> void:
	pass
	
func _process(delta: float) -> void:
	if constant_buff:
		time_accumulator += delta
		if time_accumulator > total_time:
			buff_end()

	else:
		time_accumulator += delta
		if time_accumulator >= tick_interval:
			time_accumulator -= tick_interval
			apply_buff_effect()
			ticks -= 1
			if ticks <= 0:
				buff_end()
				
func buff_end() -> void:
	buff_over.emit(ID)
	extra_end_buff_methods()
	queue_free()

func extra_end_buff_methods() -> void:
	pass
