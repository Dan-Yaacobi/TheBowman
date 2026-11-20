class_name SnowflakeSwarmData extends EnemyData
## Swarm tuning. The swarm itself is an invisible, unhittable centre; its flakes are the enemies.
## All values are first guesses.

@export_subgroup("Swarm")
@export var flake_scene: PackedScene
@export var flake_data: EnemyData
@export var min_flakes: int = 4
@export var max_flakes: int = 6
## The centre hovers at this offset from the player...
@export var hover_offset: Vector2 = Vector2(0.0, -60.0)
## ...and stops closing in at this distance from that point
@export var hover_distance: float = 90.0
@export var orbit_radius: float = 22.0
## Radians per second
@export var orbit_speed: float = 2.5
## Seconds after a flake shatters on its own before a new one forms on the circle
@export var respawn_delay: float = 1.5

@export_subgroup("Ram")
## Seconds between one flake's ram ending and the next one starting
@export var ram_interval: float = 1.2
@export var windup_time: float = 0.5
## Last part of the windup where the aim stops following the player
@export var aim_lock_time: float = 0.15
## Pull-back speed during the windup
@export var windup_pullback_speed: float = 40.0
@export var ram_speed: float = 300.0
## Shatters after flying this long without hitting anything
@export var ram_time: float = 0.6
