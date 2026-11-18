class_name ProjectileShatter extends Sprite2D
## Shown where the sword cuts an enemy projectile apart (Parry milestone): a steel cut,
## a parry star and shards flying off (sprite sheet, plays once).

const SHEET_PATH: String = "res://Player/Abilities2.0/MilestoneAbilities/Sword/Sprites/ProjectileShatter.png"
const COLUMNS: int = 4
const ROWS: int = 3
const FRAME_COUNT: int = 12
const FRAME_TIME: float = 0.0625
## The impact point in the frame (the export's anchor).
const ANCHOR: Vector2 = Vector2(31, 21)
const BASE_SCALE: float = 0.6

## Direction of the cut. The art cuts down-right; other directions mirror it.
var cut_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	texture = load(SHEET_PATH)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = COLUMNS
	vframes = ROWS
	centered = false
	offset = -ANCHOR
	z_index = 6
	scale = Vector2(-BASE_SCALE if cut_direction.x < 0.0 else BASE_SCALE, BASE_SCALE)
	var tween: Tween = create_tween()
	tween.tween_method(func(index: int) -> void: frame = index, 0, FRAME_COUNT - 1, FRAME_TIME * (FRAME_COUNT - 1))
	tween.tween_interval(FRAME_TIME)
	tween.tween_callback(queue_free)
	EventBus.camera_shake.emit(1.0, 10.0)
	GeneralFunctions.hit_freeze(0.04)
