class_name HourglassAbility extends PlayerPassiveAbility
## Hourglass Band: perfect hits in a row (streak_needed) slow the whole game for a moment.
## A quick-shot hit or a miss breaks the streak. Pips above the archer show progress.
## The slow-motion length scales with the ring's color level.

const COUNTED_META: StringName = &"hourglass_counted"
## Above the other streak pips.
const PIPS_OFFSET: Vector2 = Vector2(0, -46)

@export var streak_needed: int = 3
## Game speed during the slow (0.5 = half speed).
@export var slow_scale: float = 0.5
## Real seconds the slow lasts.
@export var slow_duration: float = 1.0

var _streak: int = 0
var _slowing: bool = false
var _token: int = 0
var _pips: PerfectStreakMinor.StreakPips

func on_equipped() -> void:
	if not EventBus.arrow_enemy_hit.is_connected(_on_event_bus_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.connect(_on_event_bus_arrow_enemy_hit)
	if not EventBus.arrow_missed.is_connected(_on_event_bus_arrow_missed):
		EventBus.arrow_missed.connect(_on_event_bus_arrow_missed)
	if not is_instance_valid(_pips):
		_pips = PerfectStreakMinor.StreakPips.new()
		_pips.needed = streak_needed
		PlayerManager.player.add_child(_pips)
		_pips.position = PIPS_OFFSET
	_set_streak(0)

func on_unequipped() -> void:
	if EventBus.arrow_enemy_hit.is_connected(_on_event_bus_arrow_enemy_hit):
		EventBus.arrow_enemy_hit.disconnect(_on_event_bus_arrow_enemy_hit)
	if EventBus.arrow_missed.is_connected(_on_event_bus_arrow_missed):
		EventBus.arrow_missed.disconnect(_on_event_bus_arrow_missed)
	_end_slow(_token)
	if is_instance_valid(_pips):
		_pips.queue_free()
	_pips = null

func _on_event_bus_arrow_enemy_hit(perfect: bool, arrow: Arrow, _target: Enemy) -> void:
	if _slowing or not is_instance_valid(arrow) or arrow.has_meta(COUNTED_META):
		return
	arrow.set_meta(COUNTED_META, true)
	if not perfect:
		_set_streak(0)
		return
	_set_streak(_streak + 1)
	if _streak >= streak_needed:
		_start_slow()

func _on_event_bus_arrow_missed() -> void:
	if not _slowing:
		_set_streak(0)

func _start_slow() -> void:
	_slowing = true
	_token += 1
	var token: int = _token
	GeneralFunctions.set_time_scale_base(slow_scale)
	# Real time, so the slow lasts slow_duration whatever the game speed.
	PlayerManager.player.get_tree().create_timer(slow_duration * power(), true, false, true).timeout.connect(_end_slow.bind(token))

func _end_slow(token: int) -> void:
	if token != _token or not _slowing:
		return
	_slowing = false
	GeneralFunctions.set_time_scale_base(1.0)
	_set_streak(0)

func _set_streak(count: int) -> void:
	_streak = count
	if is_instance_valid(_pips):
		_pips.set_count(_pips.needed if _slowing else _streak)

func get_tooltip() -> String:
	return "%d perfect hits in a row slow time to %d%% for %.1fs" % [streak_needed, roundi(slow_scale * 100.0), slow_duration * power()]

func get_tooltip_color() -> Color:
	return Color(0.55, 0.85, 1.0)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE
