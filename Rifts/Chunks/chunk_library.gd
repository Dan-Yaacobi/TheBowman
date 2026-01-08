class_name RiftChunkLibrary extends Resource

@export var buckets: Array[ChunkBucket]

func get_chunks(type: ChunkData.types) -> Array[ChunkData]:
	var res: Array[ChunkData] = []
	for bucket in buckets:
		if bucket.type == type:
			res = bucket.chunks
	return res
	
