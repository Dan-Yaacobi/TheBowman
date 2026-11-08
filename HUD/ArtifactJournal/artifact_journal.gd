class_name ArtifactJournal extends Control
## The artifact journal, drawn as an open book. One page per opened batch (three artifacts),
## two pages per spread; Prev/Next (or Left/Right) flip a page at the spine.
## Unfound artifacts show as "???". The spirit's line appears once explained, the after line
## once heard. Shown by the pause menu, which calls refresh() on open. Emits closed on Back.

signal closed

@export var catalog: ArtifactCatalog
@export var spirit_name: String = "Spirit of the World"
@export var unknown_name: String = "???"
@export var unexplained_hint: String = "Bring this to the spirit."
@export var flip_duration: float = 0.16

@export_group("Ink")
@export var ink_color: Color = Color("3b2614")
@export var ink_dim_color: Color = Color("7d6142")
@export var title_color: Color = Color("6b2d14")
@export var spirit_color: Color = Color("1f4f7a")
@export var after_color: Color = Color("8a5a00")
## Darkens a page while it turns.
@export var turning_shade: Color = Color(0.7, 0.65, 0.58)
@export_group("")

const ICON_SIZE: Vector2 = Vector2(64, 64)

@onready var count_label: Label = %CountLabel
@onready var book: PanelContainer = %Book
@onready var left_page: PanelContainer = %LeftPage
@onready var right_page: PanelContainer = %RightPage
@onready var left_content: VBoxContainer = %LeftContent
@onready var right_content: VBoxContainer = %RightContent
@onready var prev_button: Button = %PrevButton
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton

## Opened batches, one per page.
var _pages: Array[ArtifactBatch] = []
var _spread: int = 0
var _flipping: bool = false

func _ready() -> void:
	book.theme = _build_ink_theme()
	back_button.pressed.connect(_on_back_button_pressed)
	prev_button.pressed.connect(_flip.bind(-1))
	next_button.pressed.connect(_flip.bind(1))

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("Left"):
		_flip(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("Right"):
		_flip(1)
		get_viewport().set_input_as_handled()

## Rebuilds from Lore and opens at the spread holding the newest opened batch.
func refresh() -> void:
	_pages.clear()
	if catalog == null:
		push_warning("ArtifactJournal has no catalog")
		return
	var found: int = 0
	var total: int = 0
	var opened: bool = true
	for batch: ArtifactBatch in catalog.batches:
		if batch == null:
			continue
		for entry: ArtifactEntry in batch.entries:
			total += 1
			if entry and entry.item and Lore.has_found(entry.item.id):
				found += 1
		if opened:
			_pages.append(batch)
			# Later batches stay hidden until this one is fully found.
			opened = batch.is_complete()
	count_label.text = "Found %d / %d" % [found, total]
	@warning_ignore("integer_division")
	_spread = maxi(_pages.size() - 1, 0) / 2
	_kill_flip()
	_show_spread()
	back_button.grab_focus.call_deferred()

func _spread_count() -> int:
	@warning_ignore("integer_division")
	return maxi((_pages.size() + 1) / 2, 1)

func _show_spread() -> void:
	_fill_page(left_content, _spread * 2)
	_fill_page(right_content, _spread * 2 + 1)
	prev_button.disabled = _spread <= 0
	next_button.disabled = _spread >= _spread_count() - 1

# --- Flipping -----------------------------------------------------------------

## Folds the turning page into the spine, swaps the spread, unfolds the page on the other side.
func _flip(direction: int) -> void:
	var target: int = _spread + direction
	if _flipping or target < 0 or target >= _spread_count():
		return
	_flipping = true
	var lifting: PanelContainer = right_page if direction > 0 else left_page
	var landing: PanelContainer = left_page if direction > 0 else right_page
	_pivot_at_spine(lifting)
	_pivot_at_spine(landing)
	var tween: Tween = create_tween()
	tween.tween_property(lifting, "scale:x", 0.0, flip_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(lifting, "modulate", turning_shade, flip_duration)
	tween.tween_callback(func() -> void:
		_spread = target
		_show_spread()
		lifting.scale.x = 1.0
		lifting.modulate = Color.WHITE
		landing.scale.x = 0.0
		landing.modulate = turning_shade)
	tween.tween_property(landing, "scale:x", 1.0, flip_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(landing, "modulate", Color.WHITE, flip_duration)
	tween.tween_callback(func() -> void: _flipping = false)

func _pivot_at_spine(page: Control) -> void:
	var spine_x: float = page.size.x if page == left_page else 0.0
	page.pivot_offset = Vector2(spine_x, page.size.y * 0.5)

func _kill_flip() -> void:
	_flipping = false
	for page: Control in [left_page, right_page]:
		page.scale = Vector2.ONE
		page.modulate = Color.WHITE

# --- Pages --------------------------------------------------------------------

func _fill_page(content: VBoxContainer, page_index: int) -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if page_index >= _pages.size():
		return
	var batch: ArtifactBatch = _pages[page_index]
	var header: Label = Label.new()
	header.theme_type_variation = &"HeaderLabel"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.text = batch.title
	content.add_child(header)
	content.add_child(HSeparator.new())
	for entry: ArtifactEntry in batch.entries:
		if entry and entry.item:
			content.add_child(_build_entry(entry.item))
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var number: Label = Label.new()
	number.theme_type_variation = &"DimLabel"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.text = str(page_index + 1)
	content.add_child(number)

func _build_entry(item: LoreItemData) -> Control:
	var found: bool = Lore.has_found(item.id)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon.texture = item.icon if found else null
	# No sprite yet: skip the slot rather than leave a gap.
	icon.visible = item.icon != null
	row.add_child(icon)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	var name_label: Label = Label.new()
	name_label.theme_type_variation = &"TitleInkLabel" if found else &"DimLabel"
	name_label.text = item.display_name if found else unknown_name
	column.add_child(name_label)
	if found:
		var text: RichTextLabel = RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = _entry_text(item)
		column.add_child(text)
	row.add_child(column)
	return row

func _entry_text(item: LoreItemData) -> String:
	var parts: Array[String] = [item.pickup_line]
	if Lore.is_explained(item.id):
		parts.append(_quote(item.spirit_lines, spirit_color))
		if Lore.after_heard.has(item.id):
			parts.append(_quote(item.after_lines, after_color))
	else:
		parts.append("[color=#%s]%s[/color]" % [ink_dim_color.to_html(false), unexplained_hint])
	return "\n".join(parts)

func _quote(lines: Array[String], color: Color) -> String:
	return "[color=#%s]\"%s\"[/color]" % [color.to_html(false), " ".join(lines)]

## Dark ink on parchment: the game theme's light, outlined text doesn't read on the pages.
func _build_ink_theme() -> Theme:
	var t: Theme = Theme.new()
	for type: StringName in [&"Label", &"RichTextLabel"]:
		t.set_constant("outline_size", type, 0)
		t.set_color("font_shadow_color", type, Color.TRANSPARENT)
	t.set_color("font_color", &"Label", ink_color)
	t.set_color("default_color", &"RichTextLabel", ink_color)
	t.set_type_variation(&"HeaderLabel", &"Label")
	t.set_color("font_color", &"HeaderLabel", title_color)
	t.set_type_variation(&"TitleInkLabel", &"Label")
	t.set_color("font_color", &"TitleInkLabel", title_color)
	t.set_type_variation(&"DimLabel", &"Label")
	t.set_color("font_color", &"DimLabel", ink_dim_color)
	return t

func _on_back_button_pressed() -> void:
	closed.emit()
