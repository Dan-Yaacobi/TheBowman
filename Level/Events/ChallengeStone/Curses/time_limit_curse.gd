class_name TimeLimitCurse extends ChallengeCurse

## Multiplies the goal's time limit (0.5 = half the time).
@export var time_multiplier: float = 0.5

func apply(challenge: ChallengeStoneEvent) -> void:
	var goal: ChallengeGoal = challenge.goal
	if "time_limit" in goal:
		goal.set("time_limit", goal.get("time_limit") * time_multiplier)
	else:
		push_warning("TimeLimitCurse: this challenge's goal has no time_limit.")
