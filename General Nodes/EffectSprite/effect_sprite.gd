class_name EffectSprite extends Sprite2D
## Plays an EffectSheet once (then frees itself) or on a loop. Keeps its world size and stays
## upright whatever it's attached to, so a status looks the same on a 0.2-scale wizard and a bird.
##   EffectSprite.spawn(&"crit_hit", pos)           one-shot in the current world
##   EffectSprite.attach(&"status_burn", parent, p)  child of a node (statuses, followers)

## Master switch while the new effects are being tested: off = only the old effects play.
static var enabled: bool = true

const SHEET_DIR: String = "res://General Nodes/EffectSprite/Resource/"

var sheet: EffectSheet
## Extra size on top of the sheet's world scale (e.g. fitting the ice block to an enemy).
var size_mult: float = 1.0
var mirrored: bool = false
var _time: float = 0.0

static func load_sheet(sheet_name: StringName) -> EffectSheet:
	return load(SHEET_DIR + String(sheet_name) + ".tres") as EffectSheet

## A one-shot (or loop) in the world at a global position. Returns null while disabled.
static func spawn(sheet_name: StringName, at: Vector2, angle: float = 0.0, tint: Color = Color.WHITE, flip: bool = false) -> EffectSprite:
	if not enabled:
		return null
	var effect: EffectSprite = _make(sheet_name, tint, flip)
	if effect == null:
		return null
	effect.global_position = at
	effect.rotation = angle
	EventBus.summon_effect.emit(effect)
	return effect

## Attached to a node at a local position: moves with it, keeps its own world size.
static func attach(sheet_name: StringName, parent: Node, local_position: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE, flip: bool = false) -> EffectSprite:
	if not enabled or not is_instance_valid(parent):
		return null
	var effect: EffectSprite = _make(sheet_name, tint, flip)
	if effect == null:
		return null
	effect.position = local_position
	parent.add_child(effect)
	return effect

static func _make(sheet_name: StringName, tint: Color, flip: bool) -> EffectSprite:
	var data: EffectSheet = load_sheet(sheet_name)
	if data == null:
		push_warning("EffectSprite: no sheet named %s" % sheet_name)
		return null
	var effect: EffectSprite = EffectSprite.new()
	effect.sheet = data
	effect.modulate = tint
	effect.mirrored = flip
	return effect

func _ready() -> void:
	texture = sheet.texture
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = maxi(sheet.columns, 1)
	vframes = maxi(sheet.rows, 1)
	centered = false
	offset = -sheet.anchor
	frame = 0
	_keep_world_size()

func _process(delta: float) -> void:
	_keep_world_size()
	_time += delta
	var index: int = int(_time * sheet.fps)
	if index >= sheet.frame_count:
		if not sheet.loop:
			queue_free()
			return
		index %= sheet.frame_count
	frame = index

## Undo the parent's scale so the effect is always sheet.world_scale big in the world.
func _keep_world_size() -> void:
	var parent_scale: Vector2 = Vector2.ONE
	var parent_2d: Node2D = get_parent() as Node2D
	if parent_2d:
		parent_scale = parent_2d.global_scale.abs()
	var size: float = sheet.world_scale * size_mult
	scale = Vector2(size / maxf(parent_scale.x, 0.0001), size / maxf(parent_scale.y, 0.0001))
	if mirrored:
		scale.x = -scale.x
