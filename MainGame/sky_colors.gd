class_name SkyColors extends Resource

@export var top_color: Color
@export var bottom_color: Color
## Drifting clouds in this sky. Off for biomes like hell.
@export var show_clouds: bool = true

## The color far-away objects fade into (distant islands).
func get_haze_color() -> Color:
	return top_color.lerp(bottom_color, 0.65)
