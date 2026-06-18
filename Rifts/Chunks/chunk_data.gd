class_name ChunkData extends Resource

enum types{
	INTRO,COMBAT,TRAVERSAL,TREASURE,PORTAL,SIDE_BRANCH
}
enum biomes{
	REGULAR,ICE,FIRE
}

@export var scene: PackedScene

@export_subgroup("Type")
@export var type: types = types.TRAVERSAL
@export var allowed_biomes: Array[biomes]
@export var id: String
@export_range(1,5,1) var difficulty: int = 1
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
@export var min_rift_level: int = 1
