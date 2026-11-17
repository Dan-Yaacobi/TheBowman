class_name PineTreeData extends RootedEnemyData
## Pine tree tuning on top of the shared enemy stats. All values are first guesses.

@export_subgroup("Pine Tree")
## Seconds the arms take to grow
@export var wake_time: float = 0.5

@export_subgroup("Pinecones")
@export var pinecone_scene: PackedScene
@export var throw_cooldown: float = 1.5
## Wind-up before each throw (the arms rear back)
@export var throw_windup: float = 0.35
@export var pinecone_damage: int = 1
@export var pinecone_knockback: int = 60
## Pixels per second along the arc
@export var pinecone_speed: float = 140.0
## 1 = aims exactly where the player will be if they keep moving, 0 = where they are now
@export_range(0.0, 1.5) var lead_amount: float = 1.0

@export_subgroup("Swipe")
## Swipes instead of throwing when the player is this close horizontally...
@export var swipe_range: float = 40.0
## ...and at most this far above or below
@export var swipe_height: float = 30.0
@export var swipe_windup: float = 0.4
## How long the swipe can hit
@export var swipe_active: float = 0.15
@export var swipe_recovery: float = 0.35
@export var swipe_cooldown: float = 1.2
@export var swipe_damage: int = 2
@export var swipe_knockback: float = 280.0
## Launch direction for a swipe hit (x is flipped toward the player's side)
@export var swipe_launch_direction: Vector2 = Vector2(1.0, -0.7)
