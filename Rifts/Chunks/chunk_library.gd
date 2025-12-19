class_name RiftChunkLibrary extends Resource

@export var chunks: Array[ChunkData] = []

func pick(type: ChunkData.types, difficulty: int) -> ChunkData:
	var pool: Array[ChunkData] = []

	for c in chunks:
		if c == null:
			continue
		if c.type != type:
			continue
		if c.difficulty != difficulty:
			continue
		pool.append(c)

	if pool.is_empty():
		return null

	var total: float = 0.0
	for c: ChunkData in pool:
		total += max(0.0, c.weight)

	if total <= 0.0:
		var idx: int = randi() % pool.size()
		return pool[idx]

	var r: float = randf() * total
	var acc: float = 0.0

	for c: ChunkData in pool:
		acc += max(0.0, c.weight)
		if r <= acc:
			return c

	return pool[pool.size() - 1]
