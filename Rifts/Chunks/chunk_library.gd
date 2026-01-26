class_name RiftChunkLibrary extends Resource

@export var traversal_chunks: Dictionary[CustomVariables.directions,ChunkBucket]
@export var other_chunks: Dictionary[ChunkData.types,ChunkBucket]

func get_traversal_chunk(direction: CustomVariables.directions) -> ChunkData:
	return traversal_chunks[direction].chunks.pick_random()
	
func get_all_traversal_chunks(direction: CustomVariables.directions) -> Array[ChunkData]:
	return traversal_chunks[direction].chunks
	
func get_intro_chunk() -> ChunkData:
	return other_chunks[ChunkData.types.INTRO].chunks.pick_random()

func get_portal_chunk() -> ChunkData:
	return other_chunks[ChunkData.types.PORTAL_APPROACH].chunks.pick_random()
