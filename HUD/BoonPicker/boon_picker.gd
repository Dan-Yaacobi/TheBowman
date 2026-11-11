class_name BoonPicker extends Control
## Pick 1 of the spirit's offered boons for the next run. Opened through
## EventBus.boon_picker_requested; pauses the game until a boon is picked.

const CARD_SIZE: Vector2 = Vector2(230, 220)
const TITLE_FONT_SIZE: int = 20
const DESCRIPTION_FONT_SIZE: int = 15
const DESCRIPTION_COLOR: Color = Color(0.8, 0.8, 0.8)

@onready var cards: HBoxContainer = $Panel/MarginContainer/VBoxContainer/Cards

func _ready() -> void:
	hide()
	EventBus.boon_picker_requested.connect(_on_event_bus_boon_picker_requested)

func _on_event_bus_boon_picker_requested(offers: Array[SpiritBoon]) -> void:
	for child: Node in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for boon: SpiritBoon in offers:
		cards.add_child(_make_card(boon))
	show()
	get_tree().paused = true

func _make_card(boon: SpiritBoon) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	card.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	if boon.icon:
		var icon: TextureRect = TextureRect.new()
		icon.texture = boon.icon
		icon.custom_minimum_size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)

	var title: Label = Label.new()
	title.text = boon.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", boon.title_color)
	box.add_child(title)

	var description: Label = Label.new()
	description.text = boon.description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)
	description.add_theme_color_override("font_color", DESCRIPTION_COLOR)
	box.add_child(description)

	var choose: Button = Button.new()
	choose.text = "Choose"
	choose.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	choose.pressed.connect(_on_choose_pressed.bind(boon))
	box.add_child(choose)
	return card

func _on_choose_pressed(boon: SpiritBoon) -> void:
	if not MetaProgress.choose_boon(boon.id):
		return
	EventBus.button_click_sound.emit()
	get_tree().paused = false
	hide()
	EventBus.boon_picker_closed.emit()
