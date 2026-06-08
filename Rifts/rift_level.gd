class_name RiftLevel extends Node2D

signal get_summon_enemy(_level: int, main_progress: float, is_main_path: bool, is_side_path_terminal: bool)

var chunks: Array[RiftChunk]
var main_path_chunks: Array[RiftChunk] = []
var side_path_terminal_chunks: Array[RiftChunk] = []
var next_level: RiftLevel
var prev_level: RiftLevel
var level: int
var starting_chunk: RiftChunk
var main_path_visited_count: int = 0

func add_chunk(chunk: RiftChunk) -> void:
	chunks.append(chunk)

func summon_enemy(is_main_path: bool, is_side_path_terminal: bool) -> void:
	level = PlayerManager.player.stats.rift_level
	get_summon_enemy.emit(level, get_main_path_progress(), is_main_path, is_side_path_terminal)
	
func get_main_path_progress() -> float:
	return float(main_path_visited_count) / float(main_path_chunks.size())
