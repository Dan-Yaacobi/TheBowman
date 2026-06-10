class_name BossSpawner extends Node2D

signal boss_spawned(enemy: Enemy)

@export var boss_entry: EnemyEntry

func spawn() -> void:
	if boss_entry == null:
		return
	var factory: Callable = boss_entry.get_factory()
	var boss: Enemy = PlayerManager.player.spawn_handler.spawn_from_top(factory)
	if boss != null:
		boss_spawned.emit(boss)
