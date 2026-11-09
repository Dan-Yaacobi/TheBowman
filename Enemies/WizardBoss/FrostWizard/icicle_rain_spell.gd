class_name IcicleRainSpell extends WizardSpellState
## Drops waves of icicles on every island except a few neighbouring safe ones.
## Each wave's safe islands sit further from the player, so they have to cross the ice to reach them.

@export var icicle_scene: PackedScene
@export var waves: int = 3
## Time between the start of each wave (the last one doubles as recovery before idle)
@export var wave_interval: float = 2.5
## Seconds the icicles hang and shake before dropping
@export var telegraph_time: float = 1.4
## How many neighbouring islands stay safe each wave
@export var safe_count: int = 2
## Per wave: how many islands (ordered left to right) the nearest safe island is from the player's.
## 0 = the player's own island. The last value repeats for any extra waves.
@export var safe_offsets: Array[int] = [0, 2, 3]
@export var height_marker_id: StringName = &"meteor_height"

var _wave: int = 0
var _next_wave: float = 0.0

func on_cast_start() -> void:
	_wave = 0
	_next_wave = 0.0

func cast_process(_delta: float) -> void:
	if _wave >= waves or _elapsed < _next_wave:
		return
	if _wave > 0:
		_restart_cast_animation()
	_drop_wave(_wave)
	_wave += 1
	_next_wave += wave_interval

func is_finished() -> bool:
	return _wave >= waves and _elapsed >= _next_wave

func _drop_wave(wave: int) -> void:
	if icicle_scene == null:
		return
	var islands: Array[Island] = wizard.get_islands()
	if islands.is_empty():
		return
	islands.sort_custom(func(a: Island, b: Island) -> bool: return a.global_position.x < b.global_position.x)
	var safe: Array[Island] = _pick_safe(islands, wave)
	var marker: NamedMarker = wizard.get_marker(height_marker_id)
	var start_y: float = marker.global_position.y if marker else wizard.global_position.y
	for island: Island in islands:
		if safe.has(island):
			continue
		var icicle: Icicle = icicle_scene.instantiate()
		enemy.tag_attack(icicle)
		EventBus.summon_effect.emit(icicle)
		icicle.drop_onto(island, Vector2(island.global_position.x, start_y), telegraph_time)

# sorted: islands ordered left to right
func _pick_safe(sorted: Array[Island], wave: int) -> Array[Island]:
	var count: int = sorted.size()
	var keep: int = clampi(safe_count, 0, count)
	if keep == 0:
		return []
	var offset: int = 0
	if not safe_offsets.is_empty():
		offset = safe_offsets[mini(wave, safe_offsets.size() - 1)]
	var player_index: int = _closest_index(sorted, PlayerManager.player.global_position)
	var dir: int = 1 if randf() < 0.5 else -1
	if not _fits(player_index, offset, dir, keep, count):
		dir = -dir
	var first: int = player_index + dir * offset
	var last: int = first + dir * (keep - 1)
	var lowest: int = clampi(mini(first, last), 0, count - keep)
	return sorted.slice(lowest, lowest + keep)

func _fits(player_index: int, offset: int, dir: int, keep: int, count: int) -> bool:
	var first: int = player_index + dir * offset
	var last: int = first + dir * (keep - 1)
	return mini(first, last) >= 0 and maxi(first, last) < count

func _closest_index(sorted: Array[Island], pos: Vector2) -> int:
	var best: int = 0
	var best_dist: float = INF
	for i: int in sorted.size():
		var dist: float = sorted[i].global_position.distance_squared_to(pos)
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

func _restart_cast_animation() -> void:
	if wizard.animation_player:
		wizard.animation_player.stop()
	wizard.update_animation(cast_animation)
