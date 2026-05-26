class_name RiftLevel extends Node2D

signal get_summon_enemy(level: int)

var chunks: Array[RiftChunk]
var next_level: RiftLevel
var prev_level: RiftLevel
var level: int
var starting_chunk: RiftChunk

func add_chunk(chunk: RiftChunk) -> void:
	chunks.append(chunk)

func summon_enemy() -> void:
	level = PlayerManager.player.stats.rift_level
	get_summon_enemy.emit(level)
