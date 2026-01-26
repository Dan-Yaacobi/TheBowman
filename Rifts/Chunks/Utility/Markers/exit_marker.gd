class_name ExitMarker extends Marker2D
@onready var label: Label = $Label

@export var direction: CustomVariables.directions
@export var available: bool = true

func _ready() -> void:
	label.visible = false
	available = true

func disable() -> void:
	available = false

func enable() -> void:
	available = true
