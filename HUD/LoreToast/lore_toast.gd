class_name LoreToast extends Control
## Briefly shows a lore item's name and pickup line. Listens to EventBus.lore_item_found.

@export var fade_in: float = 0.25
@export var hold_time: float = 3.0
@export var fade_out: float = 0.6

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var line_label: Label = $Panel/VBox/LineLabel

var _tween: Tween

func _ready() -> void:
	panel.modulate.a = 0.0
	panel.visible = false
	EventBus.lore_item_found.connect(_on_event_bus_lore_item_found)

func _on_event_bus_lore_item_found(item: LoreItemData) -> void:
	name_label.text = item.display_name
	line_label.text = item.pickup_line
	panel.visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, fade_in)
	_tween.tween_interval(hold_time)
	_tween.tween_property(panel, "modulate:a", 0.0, fade_out)
	_tween.tween_callback(panel.hide)
