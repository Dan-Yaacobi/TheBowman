class_name RockGolemData extends EnemyData
## Rock golem tuning on top of the shared enemy stats.

@export_subgroup("Rock Golem")
## Wakes when the player gets this close (pixels)
@export var wake_range: float = 80.0
## Damage taken while dormant is multiplied by this
@export_range(0.0, 1.0) var dormant_damage_multiplier: float = 0.4
## 0 = full knockback, 1 = none
@export_range(0.0, 1.0) var knockback_resistance: float = 0.75
