class_name StatsUIOpenButton extends Control

@onready var stats_ui: StatsUI = $StatsUI

var closed: bool = true

func _ready() -> void:
	stats_ui.visible = false
	stats_ui.set_up_signals()
	EventBus.exit_ui.connect(close)
	
func _on_toggled(_toggled_on: bool) -> void:
	if closed:
		stats_ui.open()
	else:
		stats_ui.close()
	closed = not closed
	
func close() -> void:
	if not closed:
		stats_ui.close()
		closed = not closed
