class_name DisenchantMilestone extends Resource
## A permanent bonus unlocked once the lifetime number of disenchanted items reaches threshold.
## With repeat_every set, it is reached again every repeat_every items after that and the bonus
## stacks once per time reached. Listed in DisenchantConfig.milestones.

@export var threshold: int = 20
## 0 = reached once. Above 0 = reached again every this many items after threshold, forever.
@export var repeat_every: int = 0
@export var bonus: DisenchantBonus

func get_description() -> String:
	return bonus.get_description() if bonus else ""

## How many times this milestone is reached at a lifetime count.
func get_stacks(lifetime: int) -> int:
	if lifetime < threshold:
		return 0
	if repeat_every <= 0:
		return 1
	@warning_ignore("integer_division")
	return 1 + (lifetime - threshold) / repeat_every

## Lifetime count at which this milestone is next reached, or -1 if it never is again.
func get_next_threshold(lifetime: int) -> int:
	if lifetime < threshold:
		return threshold
	if repeat_every <= 0:
		return -1
	return threshold + get_stacks(lifetime) * repeat_every
