class_name RockGolemData extends EnemyData
## Rock golem tuning on top of the shared enemy stats.

@export_subgroup("Rock Golem")
## Wakes when the player gets this close (pixels)
@export var wake_range: float = 80.0
## Damage taken while dormant is multiplied by this
@export_range(0.0, 1.0) var dormant_damage_multiplier: float = 0.4
## 0 = full knockback, 1 = none
@export_range(0.0, 1.0) var knockback_resistance: float = 0.75

@export_subgroup("Chase")
## Stops walking this close to the player (later: punch reach)
@export var stop_distance: float = 16.0
## Keeps this far from island edges when walking or landing
@export var edge_margin: float = 8.0
## How far below the player to look for the island they're over
@export var player_ground_search_depth: float = 300.0

@export_subgroup("Jump")
## Furthest island it can jump to, horizontally / up / down (pixels)
@export var jump_reach_x: float = 150.0
@export var jump_reach_up: float = 90.0
@export var jump_reach_down: float = 220.0
## Horizontal speed in the air; sets how long a jump takes
@export var jump_speed_x: float = 170.0
## Crouch before take-off (the player's warning)
@export var jump_windup: float = 0.3
## Wait after landing before it may jump again
@export var jump_cooldown: float = 0.8

@export_subgroup("Falling")
## Dies after falling this far below where it last stood
@export var fall_death_depth: float = 400.0
