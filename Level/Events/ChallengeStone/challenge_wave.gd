class_name ChallengeWave extends Resource

## Enemy entry → how many of it spawn in this wave.
@export var enemies: Dictionary[EnemyEntry, int] = {}
@export var shuffle: bool = true

func get_spawn_list() -> Array[EnemyEntry]:
	var list: Array[EnemyEntry] = []
	for entry: EnemyEntry in enemies:
		for i: int in enemies[entry]:
			list.append(entry)
	if shuffle:
		list.shuffle()
	return list
