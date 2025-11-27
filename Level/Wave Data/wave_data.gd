class_name WaveData extends Resource

@export var current_wave: int
@export var targets_spawn: Array[int]
@export var bird_spawn: Array[int]
@export var spider_spawn: Array[int]
@export var total_enemies: int
@export var spawn_time: float = 5.0
@export var base_spawn_time: float
@export var double_spawn_chance: float
@export var boss_wave: bool = false
@export var hard_mode_money: int = 2

func calc_total_enemies() -> void:
	total_enemies = 2 + current_wave
