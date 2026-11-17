class_name ImpData extends EnemyData
## Imp tuning on top of the shared enemy stats. All values are first guesses.

@export_subgroup("Imp")
## Flying speed while rushing the player
@export var rush_speed: float = 160.0
## Starts its grab wind-up this close to the player
@export var grab_range: float = 45.0
## Stops, pulls back and glows this long before lunging: the window to dash away
@export var windup_time: float = 0.45
## Last part of the wind-up where the aim is locked (full glow): dash now to dodge
@export var aim_lock_time: float = 0.25
@export var windup_pullback_speed: float = 25.0
## Sprite tint at the end of the wind-up (values above 1 brighten)
@export var windup_glow: Color = Color(2.0, 1.1, 1.1)
## The lunge is the only time it can grab
@export var lunge_speed: float = 260.0
@export var lunge_time: float = 0.2
## After a missed lunge, backs off this long before rushing again
@export var miss_recover_time: float = 0.6
## Drag toward the nearest island edge this imp adds while latched (pixels per second)
@export var drag_speed: float = 60.0
## Where it holds on, relative to the player's origin (about the head)
@export var grab_offset: Vector2 = Vector2(0.0, -7.0)
## Sideways nudge toward the side it came from, so it doesn't cover the face exactly
@export var grab_side_offset: float = 3.0
## After being thrown off (player fell, stunned), flies away this long before rushing again
@export var recover_time: float = 1.2
@export var recover_speed: float = 90.0
## No grabs for this long after the player falls (covers the respawn and a moment to fight back)
@export var respawn_grace: float = 3.0
