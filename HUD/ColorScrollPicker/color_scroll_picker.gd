class_name ColorScrollPicker extends Control
## Opens when a color scroll is collected: pauses the game and lets the player raise one color.
## Card names, icons, tints and bonus texts are set on each ColorScrollCard in the inspector.

## Cards ignore input for this long after opening, so a held key can't pick by accident.
@export var input_delay: float = 0.3

@onready var options: HBoxContainer = $Panel/Margin/VBox/Options

var _cards: Array[ColorScrollCard] = []
var _pending: int = 0
var _is_open: bool = false

func _ready() -> void:
	hide()
	for child: Node in options.get_children():
		var card: ColorScrollCard = child as ColorScrollCard
		if card:
			_cards.append(card)
			card.chosen.connect(_on_card_chosen)
	EventBus.color_scroll_collected.connect(_on_event_bus_color_scroll_collected)

func _on_event_bus_color_scroll_collected() -> void:
	_pending += 1
	if not _is_open:
		_open()

func _open() -> void:
	_is_open = true
	_refresh()
	show()
	get_tree().paused = true

func _close() -> void:
	_is_open = false
	hide()
	get_tree().paused = false

## Refreshes the texts and blocks input briefly (also between back-to-back scrolls).
func _refresh() -> void:
	var levels: ColorLevels = PlayerManager.player.color_levels
	var power_pct: int = roundi(levels.power_per_level * 100.0)
	for card: ColorScrollCard in _cards:
		card.setup(levels.get_level(card.color), power_pct, levels.bonus_text(card.color), levels.items_of_color(card.color))
		card.set_selectable(false)
	await get_tree().create_timer(input_delay, true).timeout
	if not is_inside_tree() or not _is_open:
		return
	for card: ColorScrollCard in _cards:
		card.set_selectable(true)
	if not _cards.is_empty():
		_cards[0].focus()

func _on_card_chosen(color: CustomVariables.ItemColor) -> void:
	if not _is_open:
		return
	PlayerManager.player.color_levels.apply_scroll(color)
	_pending -= 1
	if _pending > 0:
		_refresh()
	else:
		_close()

## Swallows cancel so the pause menu can't unpause mid-choice.
func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
