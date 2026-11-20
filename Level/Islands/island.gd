class_name Island extends StaticBody2D

## Every island joins this group so spawners can find islands with free object spots
const GROUP: StringName = &"islands"

@onready var objects_spawn_markers: ObjectSpawnMarkers = $ObjectsSpawnMarkers
@export var start_island: bool = false
@export var floating: bool = false
@export var moving_island: bool = false
@export var end_point: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@export var use_fixed_frame: bool = false
@export var fixed_frame_index: int = 0
@export var textures: Array[TextureData]
@onready var respawn_marker: Marker2D = $RespawnMarker
@onready var event_portal_position: Marker2D = $EventPortalPosition
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


var start_point: Vector2
var float_amplitude: float = 3.0
var float_speed: float = 2.0
var base_height: float
var has_game_object: bool = false
## Set by the player the first time they land here.
var stepped_on: bool = false
var _move_tween: Tween
var _dip_tween: Tween
## Where a moving island is along its path (the dip is added on top).
var _path_position: Vector2
## Extra drop from dip(), added on top of floating / moving. 0 at rest.
var _dip_offset: float = 0.0
## A non-floating, non-moving island's resting spot while it dips.
var _rest_position: Vector2

func _ready() -> void:
	add_to_group(GROUP)
	base_height = global_position.y
	float_speed *= randf_range(0.5, 1.5)
	float_amplitude *= randf_range(0.5, 1.5)
	start_point = global_position
	if moving_island:
		floating = false
		_start_moving()
	setup(get_rift_type())
	
func get_rift_type() -> Rift.Type:
	var lvl: int = PlayerManager.player.stats.rift_level
	if lvl < 1 or CustomVariables.RIFTS_PER_TYPE <= 0:
		return Rift.Type.DIRT

	@warning_ignore("integer_division")
	var index: int = (lvl - 1) / CustomVariables.RIFTS_PER_TYPE
	
	if index >= Rift.Type.size():
		return Rift.Type.DIRT
	return index as Rift.Type
	
# All island motion happens here, in the physics step, as one position: path/float + dip.
# Moving the body outside the physics step, or from two places at once, could jump the
# one-way platform up into the player, who then counts as "inside" it and falls through.
func _physics_process(_delta: float) -> void:
	if floating:
		global_position.y = base_height + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude + _dip_offset
	elif moving_island:
		global_position = _path_position + Vector2(0, _dip_offset)
	elif is_dipping():
		global_position = _rest_position + Vector2(0, _dip_offset)

func _start_moving() -> void:
	_path_position = global_position
	var distance: float = start_point.distance_to(end_point)
	var duration: float = distance / 80.0
	_move_tween = create_tween()
	_move_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_move_tween.set_loops()
	_move_tween.tween_property(self, "_path_position", end_point, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func setup(rift_type: Rift.Type) -> void:
	var matching: TextureData = _get_texture_data_for_type(rift_type)
	if matching == null:
		return
	var new_sprite: AtlasTexture
	if use_fixed_frame:
		new_sprite = matching.get_sprite_at(fixed_frame_index)
	else:
		new_sprite = matching.get_random_sprite()
	if new_sprite != null:
		sprite.texture = new_sprite
		
func _get_texture_data_for_type(rift_type: Rift.Type) -> TextureData:
	for data: TextureData in textures:
		if data.type == rift_type:
			return data
	return null
	
func disable() -> void:
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)

func enable() -> void:
	set_collision_layer_value(5, true)
	set_collision_mask_value(1, true)

func spawn_game_object() -> bool:
	var possible_amount: int = objects_spawn_markers.get_total_possible_spawns()
	var final_amount: int = randi_range(1, possible_amount)
	# At most one breakable per island; the other spots get scenery.
	var placed_breakable: bool = false
	for i in range(final_amount):
		var scene: PackedScene = GameObjects.get_random_object(not placed_breakable)
		placed_breakable = placed_breakable or GameObjects.is_breakable(scene)
		var obj: GameObject = scene.instantiate()
		add_child(obj)
		var spawn_pos: Vector2 = objects_spawn_markers.get_spawn_position()
		var marker_offset: Vector2 = obj.placement_marker.global_position - obj.global_position
		obj.global_position = spawn_pos - marker_offset
		has_game_object = true
	return true

func has_free_object_spot() -> bool:
	return objects_spawn_markers.get_total_possible_spawns() > 0

## Takes one free object spot (e.g. for a ground enemy) and returns its position.
func claim_object_spot() -> Vector2:
	return objects_spawn_markers.get_spawn_position()

func has_free_center_spot() -> bool:
	return objects_spawn_markers.has_free_center()

## Takes the middle object spot and returns its position.
func claim_center_spot() -> Vector2:
	return objects_spawn_markers.get_center_position()

## Walkable top edge in global coords: x = left end, y = right end.
func get_top_span() -> Vector2:
	var rect: Rect2 = collision_shape.shape.get_rect()
	var xf: Transform2D = collision_shape.global_transform
	var a: float = (xf * rect.position).x
	var b: float = (xf * Vector2(rect.end.x, rect.position.y)).x
	return Vector2(minf(a, b), maxf(a, b))

func get_top_y() -> float:
	var rect: Rect2 = collision_shape.shape.get_rect()
	return (collision_shape.global_transform * rect.position).y

func get_top_center() -> Vector2:
	var span: Vector2 = get_top_span()
	return Vector2((span.x + span.y) * 0.5, get_top_y())

## False while the island is crumbled/disabled.
func is_solid() -> bool:
	return get_collision_layer_value(5)

func _on_player_interact() -> void:
	if _dip_tween != null and _dip_tween.is_running():
		return
	dip()
	var world = PlayerManager.player.get_parent()
	if world is GameWorld and world.has_respawns:
		EventBus.rift_respawn_position.emit(get_respawn_position())
		
## Sinks a little and springs back, e.g. when something lands on it. depth in pixels.
## Never rises above its resting height (no overshoot), so it can't push up into a body on it.
func dip(depth: float = 2.0) -> void:
	if _dip_tween != null and _dip_tween.is_running():
		return
	if not floating and not moving_island:
		_rest_position = global_position
	_dip_tween = create_tween()
	_dip_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_dip_tween.tween_property(self, "_dip_offset", depth, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dip_tween.tween_property(self, "_dip_offset", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_dip_tween.tween_callback(_settle_dip)

## Puts a resting island exactly back where it was once the dip is done.
func _settle_dip() -> void:
	_dip_offset = 0.0
	if not floating and not moving_island:
		global_position = _rest_position

func is_dipping() -> bool:
	return _dip_tween != null and _dip_tween.is_running()

func get_respawn_position() -> Vector2:
	if respawn_marker:
		return respawn_marker.global_position
	return Vector2.ZERO
	
func get_event_portal_position() -> Vector2:
	return event_portal_position.global_position
