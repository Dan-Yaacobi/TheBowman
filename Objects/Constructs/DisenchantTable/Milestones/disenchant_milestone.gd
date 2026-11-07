class_name DisenchantMilestone extends Resource
## A permanent bonus unlocked once the lifetime number of disenchanted items reaches threshold.
## Listed in DisenchantConfig.milestones.

@export var threshold: int = 10
@export var bonus: DisenchantBonus

func get_description() -> String:
	return bonus.get_description() if bonus else ""
