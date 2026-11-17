class_name RiftLevel extends Node2D

## A new chunk was entered: the spawner tops enemies up for this progress (see RiftEnemySpawner).
signal get_summon_enemy(_level: int, progress: float, is_reward_chunk: bool)
var chunks: Array[RiftChunk]
var main_path_chunks: Array[RiftChunk] = []
var side_path_terminal_chunks: Array[RiftChunk] = []
var next_level: RiftLevel
var prev_level: RiftLevel
var level: int
var starting_chunk: RiftChunk
## New chunks entered so far, main or side path alike (the player can't tell them apart).
var new_chunks_entered: int = 0

func add_chunk(chunk: RiftChunk) -> void:
	chunks.append(chunk)

func summon_enemy(is_reward_chunk: bool) -> void:
	level = PlayerManager.player.stats.rift_level
	get_summon_enemy.emit(level, get_progress(), is_reward_chunk)


## 0 at the first new chunk, 1 once as many new chunks as the main path is long have been
## entered (held at 1 after that). Detours move it forward like any other chunk.
func get_progress() -> float:
	var span: int = maxi(main_path_chunks.size() - 1, 1)
	return clampf(float(new_chunks_entered - 1) / float(span), 0.0, 1.0)
