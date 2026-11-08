class_name ArtifactJournal extends Control
## Every artifact found so far, grouped by batch. Unfound artifacts show as "???" only in
## batches that have opened. The spirit's line appears once explained, the after line once heard.
## Shown by the pause menu, which calls refresh() on open (also when the spirit asks for it).
## Emits closed on Back.

signal closed

@export var catalog: ArtifactCatalog
@export var spirit_name: String = "Spirit of the World"
@export var unknown_name: String = "???"
@export var unexplained_hint: String = "Bring this to the spirit."
@export var spirit_color: Color = Color("6fc3ff")
@export var after_color: Color = Color("ffcf5a")
@export var hint_color: Color = Color("bfa77f")

@onready var count_label: Label = %CountLabel
@onready var list: VBoxContainer = %List
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_name: Label = %DetailName
@onready var detail_text: RichTextLabel = %DetailText
@onready var empty_label: Label = %EmptyLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)

## Rebuilds the list from Lore and focuses the newest-found entry.
func refresh() -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	_show_detail(null)
	if catalog == null:
		push_warning("ArtifactJournal has no catalog")
		return
	var found: int = 0
	var total: int = 0
	var first_button: Button = null
	var opened: bool = true
	for batch: ArtifactBatch in catalog.batches:
		if batch == null:
			continue
		total += batch.entries.size()
		if not opened:
			continue
		var header: Label = Label.new()
		header.theme_type_variation = &"HeaderLabel"
		header.text = batch.title
		list.add_child(header)
		for entry: ArtifactEntry in batch.entries:
			if entry == null or entry.item == null:
				continue
			var button: Button = Button.new()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if Lore.has_found(entry.item.id):
				found += 1
				button.text = entry.item.display_name
				button.pressed.connect(_show_detail.bind(entry.item))
				button.focus_entered.connect(_show_detail.bind(entry.item))
				if first_button == null:
					first_button = button
			else:
				button.text = unknown_name
				button.disabled = true
			list.add_child(button)
		# Later batches stay hidden until this one is fully found.
		opened = batch.is_complete()
	count_label.text = "Found %d / %d" % [found, total]
	empty_label.visible = first_button == null
	if first_button:
		first_button.grab_focus.call_deferred()
		_show_detail(_first_found())
	else:
		back_button.grab_focus.call_deferred()

func _first_found() -> LoreItemData:
	for batch: ArtifactBatch in catalog.batches:
		for entry: ArtifactEntry in batch.entries:
			if entry and entry.item and Lore.has_found(entry.item.id):
				return entry.item
	return null

func _show_detail(item: LoreItemData) -> void:
	detail_icon.visible = item != null and item.icon != null
	detail_name.visible = item != null
	detail_text.visible = item != null
	if item == null:
		return
	detail_icon.texture = item.icon
	detail_name.text = item.display_name
	var parts: Array[String] = [item.pickup_line]
	if Lore.is_explained(item.id):
		parts.append(_quote(item.spirit_lines, spirit_color))
		if Lore.after_heard.has(item.id):
			parts.append(_quote(item.after_lines, after_color))
	else:
		parts.append("[color=#%s]%s[/color]" % [hint_color.to_html(false), unexplained_hint])
	detail_text.text = "\n\n".join(parts)

func _quote(lines: Array[String], color: Color) -> String:
	return "[color=#%s]%s:[/color]\n\"%s\"" % [color.to_html(false), spirit_name, " ".join(lines)]

func _on_back_button_pressed() -> void:
	closed.emit()
