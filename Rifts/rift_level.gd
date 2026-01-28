class_name RiftLevel extends Node2D

var chunks: Array[RiftChunk]
var next_level: RiftLevel
var prev_level: RiftLevel
var level: int
var starting_chunk: RiftChunk

func add_chunk(chunk: RiftChunk) -> void:
	chunks.append(chunk)
