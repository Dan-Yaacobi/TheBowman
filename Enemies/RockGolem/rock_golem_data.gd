class_name RockGolemData extends EnemyData
## Rock golem tuning on top of the shared enemy stats.

@export_subgroup("Rock Golem")
## Wakes when the player gets this close (pixels)
@export var wake_range: float = 80.0
## Damage taken while dormant is multiplied by this
@export_range(0.0, 1.0) var dormant_damage_multiplier: float = 0.4
## 0 = full knockback, 1 = none
@export_range(0.0, 1.0) var knockback_resistance: float = 0.75
## Size once awake (1 = the size of the dormant rock). It grows into this while waking.
@export var awake_size: float = 1.4

@export_subgroup("Chase")
## Stops walking this close to the player (later: punch reach)
@export var stop_distance: float = 22.0
## Keeps this far from island edges when walking or landing
@export var edge_margin: float = 11.0
## How far below the player to look for the island they're over
@export var player_ground_search_depth: float = 300.0

@export_subgroup("Jump")
## Furthest island it can jump to, horizontally / up / down (pixels)
@export var jump_reach_x: float = 150.0
@export var jump_reach_up: float = 90.0
@export var jump_reach_down: float = 220.0
## Horizontal speed in the air (constant, like a thrown rock); sets how long a jump takes
@export var jump_speed_x: float = 120.0
## Shortest / longest time in the air (seconds)
@export var jump_min_time: float = 0.55
@export var jump_max_time: float = 1.0
## Peak height above the higher of take-off and landing. Kept low: it hops, it doesn't fly
@export var jump_arc_height: float = 10.0
## How sharply the fall speeds up (exponential). Higher = drops like a stone
@export var jump_fall_sharpness: float = 3.0
## Rumbles in place before take-off (the player's warning)
@export var jump_windup: float = 0.5
## How far the rumble shakes the body (pixels)
@export var jump_rumble: float = 0.75
## Stands still after landing before it can act (longer if the island is still bouncing)
@export var jump_land_recovery: float = 0.3
## How far the island sinks when it lands
@export var land_island_dip: float = 4.0
## Camera shake on landing, only when the player is within shake range
@export var land_shake_strength: float = 1.2
@export var land_shake_range: float = 250.0
## Wait after landing before it may jump again
@export var jump_cooldown: float = 0.8

@export_subgroup("Falling")
## Dies after falling this far below where it last stood
@export var fall_death_depth: float = 400.0

@export_subgroup("Punch")
## Starts a punch when the player is this close horizontally (fist reach)
@export var punch_range: float = 34.0
## ...and no further apart vertically than this
@export var punch_height_tolerance: float = 28.0
@export var punch_damage: int = 4
@export var punch_knockback: float = 350.0
## Launch direction for a punch facing right (mirrored when facing left); up is negative y
@export var punch_launch_direction: Vector2 = Vector2(1.0, -0.4)
## Wait after a punch before the next one
@export var punch_cooldown: float = 1.2
