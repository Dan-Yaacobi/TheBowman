class_name WavesGoal extends ChallengeGoal

@export var waves: Array[ChallengeWave] = []
@export var break_between_waves: float = 2.0

var _challenge: ChallengeStoneEvent
var _wave_index: int = -1
var _break_left: float = 0.0

func uses_continuous_spawn() -> bool:
	return false

func start(challenge: ChallengeStoneEvent) -> void:
	_challenge = challenge
	_wave_index = -1
	_break_left = 0.0
	if waves.is_empty():
		push_warning("WavesGoal has no waves.")

func tick(delta: float) -> void:
	var spawner: ChallengeSpawner = _challenge.spawner
	if spawner.is_spawning or spawner.alive_count > 0:
		return
	if _wave_index >= waves.size() - 1:
		completed.emit()
		return
	_break_left -= delta
	if _break_left <= 0.0:
		_wave_index += 1
		_break_left = break_between_waves
		spawner.spawn_wave(waves[_wave_index].get_spawn_list())
		
func get_progress_text() -> String:
	return "Wave %d / %d" % [maxi(_wave_index + 1, 1), waves.size()]
