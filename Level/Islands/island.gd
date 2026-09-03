class_name Island extends StaticBody2D

@onready var objects_spawn_markers: ObjectSpawnMarkers = $ObjectsSpawnMarkers
@export var start_island: bool = false
@export var floating: bool
@export var moving_island: bool = false
@export var end_point: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@export var use_fixed_frame: bool = false
@export var fixed_frame_index: int = 0
@export var textures: Array[TextureData]


var start_point: Vector2
var float_amplitude: float = 3.0
var float_speed: float = 2.0
var base_height: float
var has_game_object: bool = false
var _move_tween: Tween
var _dip_tween: Tween

func _ready() -> void:
	floating = false
	base_height = global_position.y
	float_speed *= randf_range(0.5, 1.5)
	float_amplitude *= randf_range(0.5, 1.5)
	start_point = global_position
	if moving_island:
		floating = false
		_start_moving()

func _process(_delta: float) -> void:
	if floating:
		global_position.y = base_height + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude

func _start_moving() -> void:
	var distance: float = start_point.distance_to(end_point)
	var duration: float = distance / 80.0
	_move_tween = create_tween()
	_move_tween.set_loops()
	_move_tween.tween_property(self, "global_position", end_point, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
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
	for i in range(final_amount):
		var obj: GameObject = GameObjects.get_random_object().instantiate()
		add_child(obj)
		var spawn_pos: Vector2 = objects_spawn_markers.get_spawn_position()
		var marker_offset: Vector2 = obj.placement_marker.global_position - obj.global_position
		obj.global_position = spawn_pos - marker_offset
		has_game_object = true
	return true

func _on_player_interact() -> void:
	if _dip_tween != null and _dip_tween.is_running():
		return
	var original_position: Vector2 = position
	var dip_offset: Vector2 = Vector2(0, 2)
	_dip_tween = create_tween()
	_dip_tween.tween_property(self, "position", original_position + dip_offset, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_dip_tween.tween_property(self, "position", original_position, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
