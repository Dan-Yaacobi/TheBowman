class_name BossSpawner extends Node2D

signal boss_spawned(enemy: Enemy)

@export var boss_entry: Array[EnemyEntry]

func spawn(_level: int, _health_bar: HealthBar) -> void:
	if boss_entry == null:
		return
	@warning_ignore("integer_division")
	var factory: Callable = boss_entry[max(0,(_level- 2)/2)].get_factory()
	var boss: Boss = PlayerManager.player.spawn_handler.spawn_from_top(factory)
	boss.boss_health_bar = _health_bar
	if boss != null:
		boss_spawned.emit(boss)
