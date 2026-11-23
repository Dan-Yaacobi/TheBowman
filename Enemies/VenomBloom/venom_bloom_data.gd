class_name VenomBloomData extends RootedEnemyData
## Venom bloom tuning on top of the shared rooted-enemy stats. All values are first guesses.
## The stings' poison comes from a PoisonHitEffect in hit_effects.

@export_subgroup("Venom Bloom")
## Seconds after waking before the first spit wind-up starts
@export var first_spit_delay: float = 0.3

@export_subgroup("Stings")
@export var sting_scene: PackedScene
@export var spit_cooldown: float = 1.8
## Wind-up before each spit (the head rears back), the telegraph
@export var spit_windup: float = 0.45
@export_range(1, 7) var sting_count: int = 3
## Angle between neighbouring stings in the fan (degrees)
@export var sting_spread: float = 14.0
@export var sting_speed: float = 150.0
@export var sting_damage: int = 1
@export var sting_knockback: int = 50
## Stings disappear after this many seconds
@export var sting_lifetime: float = 2.0

@export_subgroup("Bite")
## Bites instead of spitting when the player is this close horizontally...
@export var bite_range: float = 36.0
## ...and at most this far above or below
@export var bite_height: float = 30.0
@export var bite_windup: float = 0.35
## How long the bite can hit
@export var bite_active: float = 0.12
@export var bite_recovery: float = 0.4
@export var bite_cooldown: float = 1.2
@export var bite_damage: int = 2
@export var bite_knockback: float = 260.0
## Launch direction for a bite hit (x is flipped toward the player's side)
@export var bite_launch_direction: Vector2 = Vector2(1.0, -0.6)
