class_name ObsidianSpireData extends RootedEnemyData
## Obsidian spire tuning on top of the shared rooted-enemy stats. All values are first guesses.

@export_subgroup("Burst")
@export var shard_scene: PackedScene
## Seconds it glows brighter before bursting (the telegraph)
@export var charge_time: float = 1.0
## Seconds between a burst and the next charge
@export var burst_cooldown: float = 2.0
@export_range(3, 24) var shard_count: int = 10
## Every other burst is turned by half a gap, so the safe gaps move
@export var alternate_gaps: bool = true
@export var shard_speed: float = 110.0
@export var shard_damage: int = 2
@export var shard_knockback: int = 120
## Shards disappear after this many seconds
@export var shard_lifetime: float = 2.5
## Sprite tint at full charge (values above 1 brighten)
@export var glow_color: Color = Color(2.2, 1.2, 0.5)
