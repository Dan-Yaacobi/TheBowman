class_name BossSpawner extends Node2D

signal boss_spawned(enemy: Enemy)

@export var boss_entry: Array[EnemyEntry]

func spawn(_level: int, _health_bar: HealthBar) -> void:
	if boss_entry == null:
		return
	@warning_ignore("integer_division")
	# One boss per biome: rifts 1..RIFTS_PER_TYPE end in boss 0, and so on.
	var index: int = mini(boss_entry.size() - 1, maxi(0, (_level - 1) / CustomVariables.RIFTS_PER_TYPE))
	var factory: Callable = boss_entry[index].get_factory()
	var boss: Boss = PlayerManager.player.spawn_handler.spawn_from_top(factory)
	boss.boss_health_bar = _health_bar
	if boss != null:
		boss_spawned.emit(boss)
