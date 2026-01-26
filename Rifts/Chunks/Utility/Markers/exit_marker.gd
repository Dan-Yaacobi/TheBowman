class_name ExitMarker extends Marker2D
@onready var label: Label = $Label

@export var direction: CustomVariables.directions

func _ready() -> void:
	label.visible = false
