class_name GoldenApple extends Enemy

## Skittish golden apple chased in the Golden Apple event.
## Skeleton: hit rules, movement and escape come in later steps.

func extra_ready_functions() -> void:
	state_machine.Initialize(self)
