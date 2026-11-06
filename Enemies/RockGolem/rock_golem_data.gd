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
## Peak height above the higher of take-off and landing, plus a little per pixel of distance.
## Kept low: it hops, it doesn't fly
@export var jump_arc_height: float = 10.0
@export var jump_arc_per_distance: float = 0.1
## Gravity of the arc. High = short, sudden hop (heavy). Sets the time in the air
@export var jump_gravity: float = 1400.0
## Extra pull on the way down so it slams into the island
@export var jump_fall_gravity_multiplier: float = 1.6
## Stands still before take-off (the player's warning)
@export var jump_windup: float = 0.6
## Stands still after landing before it can act (longer if the island is still bouncing)
@export var jump_land_recovery: float = 0.4
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

@export_subgroup("Throw")
## Throws a boulder when it hasn't landed a punch for this long (seconds awake)
@export var throw_delay: float = 10.0
## Only throws when the player is this close
@export var throw_range: float = 300.0
## Boulder scene (the earth wizard's boulder)
@export var boulder_scene: PackedScene
@export var boulder_damage: int = 3
@export var boulder_knockback: float = 260.0
## Seconds from release to landing
@export var boulder_flight_time: float = 1.1
## The golem's own boulder art, so the thrown boulder is the one it was holding
@export var boulder_texture: Texture2D
## Pixel scale of the golem's art (its Sprite2D scale), so the boulder matches it
@export var boulder_sprite_scale: float = 0.4
