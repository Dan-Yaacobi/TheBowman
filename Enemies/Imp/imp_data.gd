class_name ImpData extends EnemyData
## Imp tuning on top of the shared enemy stats. All values are first guesses.

@export_subgroup("Imp")
## Flying speed while rushing the player
@export var rush_speed: float = 160.0
## Drag toward the nearest island edge this imp adds while latched (pixels per second)
@export var drag_speed: float = 30.0
## After being thrown off (player fell, stunned), flies away this long before rushing again
@export var recover_time: float = 1.2
@export var recover_speed: float = 90.0
