class_name TextureData
extends Resource

@export var texture: Texture2D
@export var type: Rift.Type
@export var hframes: int = 1
@export var vframes: int = 1
@export var totalframes: int

func get_frame_count() -> int:
	return hframes * vframes

func get_random_frame_index() -> int:
	var max_index: int = get_frame_count() - 1
	var roll: int = randi() % totalframes
	return mini(roll, max_index)

func get_random_sprite() -> AtlasTexture:
	if texture == null or hframes <= 0 or vframes <= 0 or totalframes <= 0:
		return null

	var frame_index: int = get_random_frame_index()
	var frame_width: float = texture.get_width() / float(hframes)
	var frame_height: float = texture.get_height() / float(vframes)
	var col: int = frame_index % hframes
	var row: int = frame_index / hframes

	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
	return atlas
	
func get_sprite_at(frame_index: int) -> AtlasTexture:
	if texture == null or hframes <= 0 or vframes <= 0 or totalframes <= 0:
		return null

	var max_index: int = totalframes - 1
	var clamped_index: int = clampi(frame_index, 0, max_index)
	var frame_width: float = texture.get_width() / float(hframes)
	var frame_height: float = texture.get_height() / float(vframes)
	var col: int = clamped_index % hframes
	var row: int = clamped_index / hframes

	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(col * frame_width, row * frame_height, frame_width, frame_height)
	return atlas
