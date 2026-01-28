class_name ExitMarker extends Marker2D
@onready var label: Label = $Label

@export var direction: CustomVariables.directions
@export var available: bool = true

func _ready() -> void:
	#label.visible = false
	enable()

func disable() -> void:
	available = false
	label.add_theme_color_override("font_color", Color.RED)
	
func enable() -> void:
	label.add_theme_color_override("font_color", Color.WHITE)
	available = true
