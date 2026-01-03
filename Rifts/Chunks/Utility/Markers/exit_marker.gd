class_name ExitMarker extends Marker2D
@onready var label: Label = $Label

func _ready() -> void:
	label.visible = false
