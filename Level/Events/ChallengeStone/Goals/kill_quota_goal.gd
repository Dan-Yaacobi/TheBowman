class_name KillQuotaGoal extends ChallengeGoal

@export var kills_required: int = 20
@export var time_limit: float = 60.0

var _kills: int = 0
var _time_left: float = 0.0

func start(_challenge: ChallengeStoneEvent) -> void:
	_kills = 0
	_time_left = time_limit

func tick(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		failed.emit("Out of time")

func on_enemy_killed(_enemy: Enemy) -> void:
	_kills += 1
	if _kills >= kills_required:
		completed.emit()

func get_progress_text() -> String:
	return "%d / %d   %ds" % [_kills, kills_required, ceili(_time_left)]
