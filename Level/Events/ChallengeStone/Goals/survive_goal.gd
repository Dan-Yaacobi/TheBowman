class_name SurviveGoal extends ChallengeGoal

@export var duration: float = 45.0

var _time_left: float = 0.0

func start(_challenge: ChallengeStoneEvent) -> void:
	_time_left = duration

func tick(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		completed.emit()

func get_progress_text() -> String:
	return "Survive %ds" % ceili(_time_left)
