class_name Island extends StaticBody2D

## Every island joins this group so spawners can find islands with free object spots
const GROUP: StringName = &"islands"

## What makes a moving island move.
enum MoveTrigger { ALWAYS, PLAYER_ON_IT, SWITCHES }
## What makes a crumbling island crumble.
enum CrumbleTrigger { LANDINGS, SWITCHES }

const CRUMBLE_EFFECT_PATH: String = "res://Enemies/WizardBoss/EarthWizard/CrumbleBurst.tscn"

@onready var objects_spawn_markers: ObjectSpawnMarkers = $ObjectsSpawnMarkers
@export var start_island: bool = false
@export var floating: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@export var use_fixed_frame: bool = false
@export var fixed_frame_index: int = 0
@export var textures: Array[TextureData]

@export_group("Moving")
## Moves back and forth between where it's placed and move_offset from there.
@export var moving_island: bool = false
## The far end of the path, relative to where the island is placed.
@export var move_offset: Vector2 = Vector2(80, 0)
@export var move_speed: float = 40.0
## Seconds it waits at each end.
@export var move_end_pause: float = 0.5
## ALWAYS: moves from the start. PLAYER_ON_IT: only while the player stands on it.
## SWITCHES: only while every switch is on. Otherwise it waits where it is.
@export var move_trigger: MoveTrigger = MoveTrigger.ALWAYS

@export_group("Crumbling")
## Shakes, then falls apart (a faint ghost stays), then reforms after crumble_reform_time.
@export var crumbling: bool = false
## LANDINGS: after the player lands on it crumble_after_landings times.
## SWITCHES: once every switch is on.
@export var crumble_trigger: CrumbleTrigger = CrumbleTrigger.LANDINGS
@export_range(2, 20) var crumble_after_landings: int = 2
## Seconds it shakes before falling apart.
@export var crumble_shake_time: float = 0.6
## Seconds until it comes back. 0 = stays crumbled.
@export var crumble_reform_time: float = 3.0

@export_group("Switches")
## Switches for the SWITCHES triggers. All of them must be on.
@export var switches: Array[IslandSwitch] = []
@export_group("")
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
var _dip_tween: Tween
## Where a moving island is along its path (the dip is added on top).
var _path_position: Vector2
## Extra drop from dip(), added on top of floating / moving. 0 at rest.
var _dip_offset: float = 0.0
## A non-floating, non-moving island's resting spot while it dips.
var _rest_position: Vector2
## Heading to the far end (start_point + move_offset) or back to start_point.
var _moving_out: bool = true
var _move_wait: float = 0.0
var _landings: int = 0
var _crumble_tween: Tween

func _ready() -> void:
	add_to_group(GROUP)
	base_height = global_position.y
	float_speed *= randf_range(0.5, 1.5)
	float_amplitude *= randf_range(0.5, 1.5)
	start_point = global_position
	if moving_island:
		floating = false
		_path_position = global_position
	for island_switch: IslandSwitch in switches:
		if island_switch:
			island_switch.switched.connect(_on_island_switch_switched)
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
		var previous: Vector2 = _path_position
		if _is_move_active():
			_advance_path(_delta)
		global_position = _path_position + Vector2(0, _dip_offset)
		# Moving the body by position gives riders nothing to follow; this carries whoever
		# stands on it (player, ground enemies) along with the path.
		constant_linear_velocity = (_path_position - previous) / _delta if _delta > 0.0 else Vector2.ZERO
	elif is_dipping():
		global_position = _rest_position + Vector2(0, _dip_offset)

func _is_move_active() -> bool:
	match move_trigger:
		MoveTrigger.PLAYER_ON_IT:
			return is_player_on_it()
		MoveTrigger.SWITCHES:
			return are_switches_on()
	return true

func _advance_path(delta: float) -> void:
	if _move_wait > 0.0:
		_move_wait -= delta
		return
	var target: Vector2 = start_point + move_offset if _moving_out else start_point
	_path_position = _path_position.move_toward(target, move_speed * delta)
	if _path_position.is_equal_approx(target):
		_moving_out = not _moving_out
		_move_wait = move_end_pause

## The player is standing on this island right now.
func is_player_on_it() -> bool:
	var player: Player = PlayerManager.player
	if player == null or not player.is_on_floor():
		return false
	for i: int in player.get_slide_collision_count():
		if player.get_slide_collision(i).get_collider() == self:
			return true
	return false

## True when every assigned switch is on (and there's at least one).
func are_switches_on() -> bool:
	var any: bool = false
	for island_switch: IslandSwitch in switches:
		if island_switch == null:
			continue
		if not island_switch.is_on:
			return false
		any = true
	return any

func _on_island_switch_switched(_on: bool) -> void:
	if crumbling and crumble_trigger == CrumbleTrigger.SWITCHES and are_switches_on():
		start_crumble()
	
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
	if crumbling and crumble_trigger == CrumbleTrigger.LANDINGS and is_solid():
		_landings += 1
		if _landings >= crumble_after_landings:
			start_crumble()
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

# --- Crumbling ---

## Shakes for crumble_shake_time, then crumbles (and reforms after crumble_reform_time).
func start_crumble() -> void:
	if not is_solid() or (_crumble_tween != null and _crumble_tween.is_running()):
		return
	var base: Vector2 = sprite.position
	_crumble_tween = create_tween()
	_crumble_tween.tween_method(func(t: float) -> void:
		var amount: float = 2.0 * t
		sprite.position = base + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round(),
		0.0, 1.0, crumble_shake_time)
	_crumble_tween.tween_callback(func() -> void:
		sprite.position = base
		EventBus.camera_shake.emit(3.0, 10.0)
		crumble(0.15, null, crumble_reform_time))

## Stops being solid; only a faint ghost stays. reform_after > 0 brings it back by itself.
## Shared with the earth wizard's crumble spell.
func crumble(ghost_alpha: float = 0.15, effect: PackedScene = null, reform_after: float = 0.0) -> void:
	sprite.modulate.a = ghost_alpha
	disable()
	var fx_scene: PackedScene = effect if effect else load(CRUMBLE_EFFECT_PATH) as PackedScene
	if fx_scene:
		add_child(fx_scene.instantiate())
	_move_respawn_off()
	if reform_after > 0.0:
		get_tree().create_timer(reform_after, false).timeout.connect(reform)

## Solid again, fading back in over fade_time.
func reform(fade_time: float = 0.4) -> void:
	if not is_inside_tree():
		return
	enable()
	_landings = 0
	if fade_time <= 0.0:
		sprite.modulate.a = 1.0
		return
	create_tween().tween_property(sprite, "modulate:a", 1.0, fade_time)

## The player respawns on the last island they stood on; never leave that over a hole.
func _move_respawn_off() -> void:
	var world: GameWorld = PlayerManager.player.get_parent() as GameWorld if PlayerManager.player else null
	if world == null or not world.respawn_position.is_equal_approx(get_respawn_position()):
		return
	var best: Island = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var other: Island = node as Island
		if other == null or other == self or not other.is_solid():
			continue
		var distance: float = other.global_position.distance_squared_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	if best:
		EventBus.rift_respawn_position.emit(best.get_respawn_position())
