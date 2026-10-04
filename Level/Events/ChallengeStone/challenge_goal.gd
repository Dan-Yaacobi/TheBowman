class_name ChallengeGoal extends Resource

signal completed
signal failed(reason: String)

func start(_challenge: ChallengeStoneEvent) -> void:
	pass

func tick(_delta: float) -> void:
	pass

func on_enemy_killed(_enemy: Enemy) -> void:
	pass

func stop() -> void:
	pass

## False for goals that spawn their own enemies (waves).
func uses_continuous_spawn() -> bool:
	return true

## Shown on the HUD later.
func get_progress_text() -> String:
	return ""
