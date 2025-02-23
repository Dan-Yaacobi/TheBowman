class_name WaveData extends Resource

@export var current_wave: int
@export var targets_spawn: Array[int]
@export var bird_spawn: Array[int]
@export var total_enemies: int
@export var spawn_time: float
@export var base_spawn_time: float
@export var double_spawn_chance: float
@export var boss_wave: bool = false
@export var hard_mode_money: int = 2

func calc_total_enemies() -> void:
	total_enemies = 5 + current_wave

func spawn_time_update(hard_mode: bool) -> void:
	if not hard_mode:
		spawn_time = base_spawn_time - current_wave*0.01
		if spawn_time <= 0.5:
			spawn_time = 0.5
	else:
		spawn_time = 0.3 - current_wave*0.01
