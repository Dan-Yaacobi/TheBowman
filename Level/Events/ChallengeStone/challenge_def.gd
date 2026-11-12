class_name ChallengeDef extends Resource

@export var display_name: String
@export_multiline var description: String
@export var goal: ChallengeGoal

@export var rewards: Array[EventReward] = []

@export_group("Spawning")
## Used by goals with continuous spawning. Waves define their own enemies.
@export var enemy_pool: Array[EnemyEntry] = []
@export var spawn_interval: float = 1.5
@export var max_alive: int = 5

@export_group("Modifiers")
## Always active for this challenge (e.g. the moving zone).
@export var modifiers: Array[ChallengeModifier] = []
## Curses the shrine can offer.
@export var curse_pool: Array[ChallengeCurse] = []

@export_group("Rift Level Scaling")
## Extra enemies allowed alive at once, per rift level above 1.
@export var max_alive_per_level: float = 0.5
## Spawn interval shrinks by this fraction per rift level above 1.
@export_range(0.0, 0.2) var interval_drop_per_level: float = 0.06
@export var min_spawn_interval: float = 0.6

## Pool entries unlocked by this rift level (an enemy unlocks once the run has reached the first
## rift it can appear in). Biome limits are ignored so the roster keeps growing instead of swapping
## out. Falls back to the whole pool if nothing qualifies.
func get_pool_for_level(level: int) -> Array[EnemyEntry]:
	var pool: Array[EnemyEntry] = enemy_pool.filter(
		func(e: EnemyEntry) -> bool: return e.first_rift_level() <= level
	)
	return pool if not pool.is_empty() else enemy_pool

func get_max_alive(level: int) -> int:
	return max_alive + floori(max_alive_per_level * maxi(level - 1, 0))

func get_spawn_interval(level: int) -> float:
	var scaled: float = spawn_interval * (1.0 - interval_drop_per_level * maxi(level - 1, 0))
	return maxf(scaled, min_spawn_interval)
