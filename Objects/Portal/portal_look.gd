class_name PortalLook extends Resource
## One visual variant of the rift portal: frame sprite, swirl colours and an optional emitter
## (snow drifting out, lava pouring). Picked by Portal from where it leads.

## 80x80 frame with a blue interior (the swirl shader replaces the blue).
@export var texture: Texture2D
## Interior centre in UV space; the frames sit low on the canvas.
@export var swirl_center: Vector2 = Vector2(0.5, 0.62)
@export var deep_color: Color = Color(0.02, 0.12, 0.75)
@export var mid_color: Color = Color(0.05, 0.35, 0.95)
@export var bright_color: Color = Color(0.3, 0.85, 1.0)
@export var star_color: Color = Color(0.75, 0.95, 1.0)
## Multiplies the built-in spiral and sparkle particles.
@export var particle_tint: Color = Color.WHITE
## Extra particles, added under the sprite (units are frame pixels, centre of the frame = 0,0).
@export var emitter_scene: PackedScene
