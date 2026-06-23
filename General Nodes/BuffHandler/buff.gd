class_name Buff extends Node2D

signal buff_over(id: int)

@export var ID: int
@export var texture: Texture
@export var tooltip: String
@export var max_stacks: int
@export var constant_buff: bool
@export var ticks: int = 0
@export var duration: float

var time_accumulator: float = 0.0
var tick_interval: float
var stacks: int = 1
var entity: Node2D

func _ready() -> void:
	if ticks > 0:
		tick_interval = duration / ticks
	start_buff_effect()
	
func apply_buff_effect() -> void:
	pass

func start_buff_effect() -> void:
	pass
	
func _process(delta: float) -> void:
	if constant_buff:
		time_accumulator += delta
		if check_end_conditions():
			buff_end()

	else:
		time_accumulator += delta
		if time_accumulator >= tick_interval:
			time_accumulator -= tick_interval
			apply_buff_effect()
			ticks -= 1
			if ticks <= 0:
				buff_end()

func add_stack() -> void:
	if stacks < max_stacks:
		if constant_buff:
			apply_buff_effect()
		stacks += 1
		
func buff_end() -> void:
	buff_over.emit(ID)
	extra_end_buff_methods()
	queue_free()
	
func check_end_conditions() -> bool:
	return false
	
func extra_end_buff_methods() -> void:
	pass
