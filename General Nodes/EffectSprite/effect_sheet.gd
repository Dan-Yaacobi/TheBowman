class_name EffectSheet extends Resource
## One sprite-sheet effect (PixelLab VFX export): the sheet, its frame grid and timing,
## the anchor the effect is centred on, and how big it is drawn in the world.

@export var texture: Texture2D
@export var columns: int = 4
@export var rows: int = 4
@export var frame_count: int = 1
@export var fps: float = 12.0
@export var loop: bool = false
## Pixel in a frame that sits on the effect's position (the export's anchor).
@export var anchor: Vector2 = Vector2.ZERO
## World-space scale, kept no matter what the effect is attached to.
@export var world_scale: float = 0.6
