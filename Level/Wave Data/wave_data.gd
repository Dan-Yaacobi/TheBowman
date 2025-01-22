class_name WaveData extends Resource

@export var current_wave: int
@export var targets_spawn: Array[int]
@export var bird_spawn: Array[int]
@export var total_enemies: int
@export var spawn_time: float
@export var double_spawn_chance: float
@export var boss_wave: bool = false

func calc_total_enemies() -> void:
	total_enemies = 5 * current_wave

func spawn_time_update() -> void:
	spawn_time -= current_wave*0.01
	if spawn_time <= 1:
		spawn_time = 1
