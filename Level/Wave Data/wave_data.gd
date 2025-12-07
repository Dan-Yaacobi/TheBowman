class_name WaveData extends Resource

@export var current_wave: int
@export var targets_spawn: Array[int]
@export var bird_spawn: Array[int]
@export var spider_spawn: Array[int]
@export var total_enemies: int
@export var spawn_time: float = 5.0
@export var boss_wave: bool = false

func calc_total_enemies() -> void:
	total_enemies = 2 + current_wave
	
