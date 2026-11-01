class_name ColorLevelsHud extends HBoxContainer
## Minimal readout of the run's color levels. Updated through EventBus only.

@export var precision_color: Color = Color(0.55, 0.75, 0.95)
@export var tempo_color: Color = Color(0.95, 0.75, 0.3)
@export var elemental_color: Color = Color(0.75, 0.4, 0.85)

@onready var precision_label: Label = $PrecisionLabel
@onready var tempo_label: Label = $TempoLabel
@onready var elemental_label: Label = $ElementalLabel

func _ready() -> void:
	precision_label.modulate = precision_color
	tempo_label.modulate = tempo_color
	elemental_label.modulate = elemental_color
	for color: CustomVariables.ItemColor in CustomVariables.ItemColor.values():
		_on_event_bus_color_level_changed(color, 0)
	EventBus.color_level_changed.connect(_on_event_bus_color_level_changed)

func _on_event_bus_color_level_changed(color: CustomVariables.ItemColor, level: int) -> void:
	match color:
		CustomVariables.ItemColor.PRECISION:
			precision_label.text = "P %d" % level
		CustomVariables.ItemColor.TEMPO:
			tempo_label.text = "T %d" % level
		CustomVariables.ItemColor.ELEMENTAL:
			elemental_label.text = "E %d" % level
