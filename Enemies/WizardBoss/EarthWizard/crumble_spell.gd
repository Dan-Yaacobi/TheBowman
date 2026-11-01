class_name CrumbleSpell extends WizardSpellState
## Shakes the island the player is on, then crumbles it: it stops being solid and only a
## faint ghost stays. It returns at the start of his next Crumble, a full spell cycle later.

@export var dust_scene: PackedScene
@export var crumble_scene: PackedScene
## Seconds the island shakes before it crumbles
@export var telegraph_time: float = 1.5
## Seconds after the crumble before he returns to idle
@export var recovery_time: float = 0.4
## Island sprite jitter in pixels right before it crumbles (it builds up from 0)
@export var max_shake: float = 2.0
## Opacity of the crumbled island's ghost, so the player can see where it will return
@export var ghost_alpha: float = 0.15
## Seconds for a crumbled island to fade back in
@export var reform_time: float = 0.4
@export var crumble_camera_shake: float = 5.0
## Half an island's width, used to find the island under the player
@export var island_half_width: float = 21.5
## Vertical offset of the falling dust from the island's origin (underside)
@export var dust_offset_y: float = 8.0

var _target: Island
var _crumbled: Island
var _sprite_base: Vector2
var _dust: LingeringEffect
var _fell: bool = false

func on_cast_start() -> void:
	_fell = false
	_restore(_crumbled)
	_crumbled = null
	_target = _pick_target()
	if _target == null:
		return
	_sprite_base = _target.sprite.position
	if dust_scene:
		_dust = dust_scene.instantiate()
		_dust.position = Vector2(0.0, dust_offset_y)
		_target.add_child(_dust)

func Exit() -> void:
	# Cut short before the crumble (e.g. stunned): the island stays as it was
	if not _fell and is_instance_valid(_target):
		_target.sprite.position = _sprite_base
	_stop_dust()
	super()

func cast_process(_delta: float) -> void:
	if _fell or _target == null:
		return
	if not is_instance_valid(_target):
		_target = null
		return
	var amount: float = max_shake * clampf(_elapsed / maxf(telegraph_time, 0.01), 0.0, 1.0)
	_target.sprite.position = _sprite_base + Vector2(randf_range(-amount, amount), randf_range(-amount, amount)).round()
	if _elapsed >= telegraph_time:
		_crumble()

func is_finished() -> bool:
	return _target == null or _elapsed >= telegraph_time + recovery_time

func _crumble() -> void:
	_fell = true
	_crumbled = _target
	_target.sprite.position = _sprite_base
	_target.sprite.modulate.a = ghost_alpha
	_target.disable()
	_stop_dust()
	if crumble_scene:
		var fx: LingeringEffect = crumble_scene.instantiate()
		_target.add_child(fx)
	EventBus.camera_shake.emit(crumble_camera_shake, 10.0)
	_move_respawn_off(_target)

func _restore(island: Island) -> void:
	if not is_instance_valid(island):
		return
	island.enable()
	var tween: Tween = island.create_tween()
	tween.tween_property(island.sprite, "modulate:a", 1.0, reform_time)

# If the boss dies (or the arena closes) while an island is crumbled, put it back
func _exit_tree() -> void:
	if is_instance_valid(_crumbled) and _crumbled.is_inside_tree():
		_crumbled.enable()
		_crumbled.sprite.modulate.a = 1.0
	_crumbled = null

func _stop_dust() -> void:
	if is_instance_valid(_dust):
		_dust.stop()
	_dust = null

# The player respawns on the last island they stood on; never leave that over a hole
func _move_respawn_off(island: Island) -> void:
	var world: BossArena = wizard.arena
	if world == null or not world.respawn_position.is_equal_approx(island.get_respawn_position()):
		return
	var best: Island = null
	var best_dist: float = INF
	for other: Island in wizard.get_islands():
		if other == island or not _is_solid(other):
			continue
		var dist: float = other.global_position.distance_squared_to(island.global_position)
		if dist < best_dist:
			best_dist = dist
			best = other
	if best:
		EventBus.rift_respawn_position.emit(best.get_respawn_position())

# The island the player stands on, else the one below them, else the nearest one
func _pick_target() -> Island:
	var player: Player = PlayerManager.player
	for i: int in player.get_slide_collision_count():
		var standing: Island = player.get_slide_collision(i).get_collider() as Island
		if standing:
			return standing
	var below: Island = null
	var nearest: Island = null
	var nearest_dist: float = INF
	for island: Island in wizard.get_islands():
		if not _is_solid(island):
			continue
		var pos: Vector2 = island.global_position
		if absf(pos.x - player.global_position.x) <= island_half_width and pos.y >= player.global_position.y - 4.0:
			if below == null or pos.y < below.global_position.y:
				below = island
		var dist: float = pos.distance_squared_to(player.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = island
	return below if below else nearest

static func _is_solid(island: Island) -> bool:
	return island.get_collision_layer_value(5)
