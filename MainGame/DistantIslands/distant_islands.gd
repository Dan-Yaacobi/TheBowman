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

var _materials: Array[ShaderMaterial] = []

func _ready() -> void:
	z_index = -20
	_build_layers()
	EventBus.change_sky_color.connect(_on_event_bus_change_sky_color)

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
