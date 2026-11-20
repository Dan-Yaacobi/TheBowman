class_name DistantIslands extends Node2D
## Small islands far in the background. Builds one Parallax2D per layer and scatters
## islands over a repeating tile, so they fill the sky in every direction.
## Each layer fades toward the current sky's haze color.

const HAZE_SHADER_PATH: String = "res://MainGame/DistantIslands/distant_haze.gdshader"

@export var island_textures: Array[Texture2D] = []
@export var island_hframes: int = 1
@export var island_vframes: int = 1
@export_group("Layers")
## One entry per layer, farthest first. All "layer_" arrays must have the same size.
@export var layer_scroll_scales: Array[float] = [0.04, 0.12]
@export var layer_sprite_scales: Array[float] = [0.7, 1.0]
@export var layer_haze: Array[float] = [0.4, 0.2]
@export var layer_island_counts: Array[int] = [6, 4]
@export_group("Tiling")
## Size of the repeating tile. Must be bigger than the most zoomed-out view.
@export var repeat_size: Vector2 = Vector2(640.0, 400.0)
@export var layout_seed: int = 7
@export_group("Final Tower")
## The wizard's tower, always on the horizon. Too far away to parallax: it sits at a fixed
## spot on screen behind the islands and grows as the run gets closer to it.
@export var tower_texture: Texture2D
## Screen spot of the tower's base, as a fraction of the view (0,0 = top-left).
@export var tower_anchor: Vector2 = Vector2(0.8, 0.8)
## Tower height as a fraction of the screen height, before the first rift and after the last.
@export var tower_start_height: float = 0.3
@export var tower_end_height: float = 0.65
@export var tower_haze: float = 0.35
@export var tower_alpha: float = 0.75
@export var tower_grow_time: float = 1.5

var _materials: Array[ShaderMaterial] = []
var _tower: Sprite2D
var _tower_tween: Tween

func _ready() -> void:
	z_index = -20
	_build_layers()
	_build_tower()
	EventBus.change_sky_color.connect(_on_event_bus_change_sky_color)

## Own canvas layer between the sky (-2) and the world.
func _build_tower() -> void:
	if tower_texture == null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	_tower = Sprite2D.new()
	_tower.texture = tower_texture
	_tower.offset = Vector2(0.0, -tower_texture.get_height() * 0.5)
	_tower.modulate.a = tower_alpha
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load(HAZE_SHADER_PATH)
	mat.set_shader_parameter("haze_amount", tower_haze)
	_tower.material = mat
	_materials.append(mat)
	layer.add_child(_tower)
	_place_tower()
	_tower.scale = Vector2.ONE * _tower_scale()
	get_viewport().size_changed.connect(_place_tower)

func _place_tower() -> void:
	_tower.position = get_viewport().get_visible_rect().size * tower_anchor

## 0 before the first rift, 1 from the last rift on (boss arenas keep their biome's last level).
func _tower_scale() -> float:
	var level: int = PlayerManager.player.stats.rift_level if PlayerManager.player else 0
	var progress: float = clampf(float(level) / CustomVariables.RUN_RIFT_COUNT, 0.0, 1.0)
	var height: float = lerpf(tower_start_height, tower_end_height, progress)
	return height * get_viewport().get_visible_rect().size.y / tower_texture.get_height()

## Sky changes come with every new world, so the tower grows then.
func _grow_tower() -> void:
	if _tower == null:
		return
	if _tower_tween:
		_tower_tween.kill()
	_tower_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tower_tween.tween_property(_tower, ^"scale", Vector2.ONE * _tower_scale(), tower_grow_time)

func _build_layers() -> void:
	if island_textures.is_empty():
		return
	var shader: Shader = load(HAZE_SHADER_PATH)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = layout_seed
	for i: int in layer_scroll_scales.size():
		var layer: Parallax2D = Parallax2D.new()
		layer.scroll_scale = Vector2.ONE * layer_scroll_scales[i]
		layer.repeat_size = repeat_size
		layer.repeat_times = 3
		layer.z_index = i
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("haze_amount", layer_haze[i])
		layer.material = mat
		_materials.append(mat)
		add_child(layer)
		_scatter_islands(layer, layer_island_counts[i], layer_sprite_scales[i], rng)

## Sample cells without replacement so islands never stack on each other.
func _scatter_islands(layer: Parallax2D, count: int, sprite_scale: float, rng: RandomNumberGenerator) -> void:
	var cols: int = 4
	var rows: int = 3
	var cells: Array[int] = []
	for c: int in cols * rows:
		cells.append(c)
	var cell_size: Vector2 = repeat_size / Vector2(cols, rows)
	var frame_count: int = island_hframes * island_vframes
	for n: int in mini(count, cells.size()):
		var cell: int = cells.pop_at(rng.randi_range(0, cells.size() - 1))
		@warning_ignore("integer_division")
		var cell_origin: Vector2 = Vector2(cell % cols, cell / cols) * cell_size
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = island_textures[rng.randi_range(0, island_textures.size() - 1)]
		sprite.hframes = island_hframes
		sprite.vframes = island_vframes
		sprite.frame = rng.randi_range(0, frame_count - 1)
		sprite.use_parent_material = true
		sprite.flip_h = rng.randf() < 0.5
		sprite.scale = Vector2.ONE * sprite_scale * rng.randf_range(0.8, 1.2)
		sprite.position = cell_origin + Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)) * cell_size
		layer.add_child(sprite)

func _on_event_bus_change_sky_color(sky_colors: SkyColors) -> void:
	var haze: Color = sky_colors.get_haze_color()
	for mat: ShaderMaterial in _materials:
		mat.set_shader_parameter("haze_color", haze)
	_grow_tower()
