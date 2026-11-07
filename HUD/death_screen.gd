class_name DeathScreen extends Control
## End-of-run summary. Snapshots the RunTally when the player dies, then reveals itself
## once the hub has loaded behind it (the HUD is hidden during the scene fade).

const ROW_FONT_SIZE: int = 32
const HEADER_FONT_SIZE: int = 32
const TILE_VALUE_FONT_SIZE: int = 48
const TILE_CAPTION_FONT_SIZE: int = 16
const ICON_SIZE: Vector2 = Vector2(32, 32)

const COLOR_TEXT: Color = Color("f3e2c0")
const COLOR_DIM: Color = Color("bfa77f")
const COLOR_GOLD: Color = Color("ffcf5a")
const COLOR_ELITE: Color = Color("ff9a3c")
const COLOR_BOSS: Color = Color("ff5a4a")
const COLOR_WON: Color = Color("8fdc6a")
const COLOR_LOST: Color = Color("e0645a")

const RESOURCE_ORDER: Array[CustomVariables.items] = [
	CustomVariables.items.COIN,
	CustomVariables.items.ESSENCE,
	CustomVariables.items.WOOD,
	CustomVariables.items.SKYSHARD,
	CustomVariables.items.POTION,
	CustomVariables.items.COLOR_SCROLL,
]

## Icons for resource rows. Missing entries show the name only.
@export var item_icons: Dictionary[CustomVariables.items, Texture2D] = {}
@export var schematic_icon: Texture2D
@export var chest_icon: Texture2D
## Seconds between each row popping in.
@export var row_stagger: float = 0.035
## Seconds the summary numbers take to count up.
@export var count_up_duration: float = 0.8
## Reveal anyway if the hub never reports ready (e.g. death without a scene change).
@export var reveal_fallback_delay: float = 2.5

@onready var backdrop: ColorRect = $Backdrop
@onready var layout: VBoxContainer = $Margin/Layout
@onready var title: Label = $Margin/Layout/Title
@onready var subtitle: Label = $Margin/Layout/Subtitle
@onready var summary: HBoxContainer = $Margin/Layout/Summary
@onready var columns: HBoxContainer = $Margin/Layout/Columns
@onready var slain_list: VBoxContainer = $Margin/Layout/Columns/SlainPanel/Margin/Scroll/SlainList
@onready var loot_list: VBoxContainer = $Margin/Layout/Columns/LootPanel/Margin/Scroll/LootList
@onready var journey_list: VBoxContainer = $Margin/Layout/Columns/JourneyPanel/Margin/Scroll/JourneyList
@onready var button: Button = $Margin/Layout/Button

var tally: RunTally = RunTally.new()
var _reveal_pending: bool = false
var _rows: Array[Control] = []
var _tiles: Array[Control] = []
var _reveal_tween: Tween

func _ready() -> void:
	visible = false
	EventBus.player_died.connect(death_screen)
	EventBus.world_ready.connect(_on_event_bus_world_ready)

func death_screen(_show: bool = true) -> void:
	tally.finish()
	if not _show:
		return
	_build(PlayerManager.player.stats.rift_level)
	layout.modulate.a = 0.0
	backdrop.modulate.a = 1.0
	modulate.a = 1.0
	visible = true
	get_tree().paused = true
	_reveal_pending = true
	await get_tree().create_timer(reveal_fallback_delay, true).timeout
	if is_inside_tree():
		_reveal()

func _on_event_bus_world_ready() -> void:
	_reveal()

func _on_button_pressed() -> void:
	if _reveal_tween:
		_reveal_tween.kill()
	get_tree().paused = false
	visible = false

# --- Reveal ---------------------------------------------------------------------

func _reveal() -> void:
	if not _reveal_pending:
		return
	_reveal_pending = false
	# Scene transitions unpause the tree; keep the hub frozen behind the summary.
	get_tree().paused = true
	layout.modulate.a = 1.0
	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	button.modulate.a = 0.0
	columns.modulate.a = 0.0
	button.disabled = true
	for node: Control in _tiles:
		node.modulate.a = 0.0
	for node: Control in _rows:
		node.modulate.a = 0.0

	title.pivot_offset = title.size * 0.5
	title.scale = Vector2(1.6, 1.6)

	# One parallel tween; each step is placed on the timeline by its delay.
	_reveal_tween = create_tween().set_parallel(true)
	_reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_reveal_tween.tween_property(title, "modulate:a", 1.0, 0.25)
	_reveal_tween.tween_property(title, "scale", Vector2.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var at: float = 0.35
	_reveal_tween.tween_property(subtitle, "modulate:a", 1.0, 0.25).set_delay(at)
	at += 0.2
	for tile: Control in _tiles:
		_reveal_tween.tween_property(tile, "modulate:a", 1.0, 0.15).set_delay(at)
		var value_label: Label = tile.get_meta(&"value_label") as Label
		var target: int = int(tile.get_meta(&"target"))
		var formatter: Callable = tile.get_meta(&"formatter") as Callable
		_reveal_tween.tween_method(
			func(v: float) -> void: value_label.text = formatter.call(roundi(v)),
			0.0, float(target), count_up_duration
		).set_delay(at).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		at += 0.08
	_reveal_tween.tween_property(columns, "modulate:a", 1.0, 0.2).set_delay(at)
	at += 0.15
	# Columns fill in side by side, row by row.
	var last_row_at: float = at
	for row: Control in _rows:
		var row_at: float = at + float(row.get_meta(&"order", 0)) * row_stagger
		_reveal_tween.tween_property(row, "modulate:a", 1.0, 0.12).set_delay(row_at)
		last_row_at = maxf(last_row_at, row_at)
	at = last_row_at + 0.15
	_reveal_tween.tween_property(button, "modulate:a", 1.0, 0.25).set_delay(at)
	_reveal_tween.tween_callback(func() -> void: button.disabled = false).set_delay(at)

# --- Building -------------------------------------------------------------------

func _build(rift_level: int) -> void:
	_rows.clear()
	_tiles.clear()
	var containers: Array[Container] = [summary, slain_list, loot_list, journey_list]
	for container: Container in containers:
		for child: Node in container.get_children():
			container.remove_child(child)
			child.queue_free()

	subtitle.text = "Your journey ended on rift level %d" % rift_level

	var events_won: int = RunTally.total(tally.events_completed)
	_add_tile("Rift Level", rift_level, COLOR_GOLD)
	_add_tile("Run Time", tally.get_run_seconds(), COLOR_GOLD, _format_time)
	_add_tile("Enemies Slain", RunTally.total(tally.enemies), COLOR_TEXT)
	_add_tile("Elites", RunTally.total(tally.elites), COLOR_ELITE)
	_add_tile("Bosses", RunTally.total(tally.bosses), COLOR_BOSS)
	_add_tile("Events Won", events_won, COLOR_WON)

	_build_slain()
	_build_loot()
	_build_journey()

func _build_slain() -> void:
	_add_header(slain_list, "Slain")
	var any: bool = false
	if not tally.bosses.is_empty():
		any = true
		_add_subheader(slain_list, "Bosses", COLOR_BOSS)
		for entry: Array in RunTally.sorted_entries(tally.bosses):
			_add_row(slain_list, entry[0], "x%d" % entry[1], COLOR_BOSS)
	if not tally.elites.is_empty():
		any = true
		_add_subheader(slain_list, "Elites", COLOR_ELITE)
		for entry: Array in RunTally.sorted_entries(tally.elites):
			_add_row(slain_list, entry[0], "x%d" % entry[1], COLOR_ELITE)
	if not tally.enemies.is_empty():
		any = true
		_add_subheader(slain_list, "Enemies", COLOR_DIM)
		for entry: Array in RunTally.sorted_entries(tally.enemies):
			_add_row(slain_list, entry[0], "x%d" % entry[1])
	if not any:
		_add_empty(slain_list, "Nothing. Not even a bird.")

func _build_loot() -> void:
	_add_header(loot_list, "Spoils")
	_add_subheader(loot_list, "Resources", COLOR_DIM)
	var any_resource: bool = false
	for item: CustomVariables.items in RESOURCE_ORDER:
		var amount: int = tally.resources.get(item, 0)
		if amount <= 0:
			continue
		any_resource = true
		_add_row(loot_list, _item_name(item), str(amount), COLOR_TEXT, item_icons.get(item))
	if not any_resource:
		_add_empty(loot_list, "Pockets empty.")

	_add_subheader(loot_list, "Equipment", COLOR_DIM)
	_add_row(loot_list, "Items found", str(tally.get_equipment_total()), COLOR_GOLD)
	var rarities: Array[int] = []
	rarities.assign(tally.equipment_by_rarity.keys())
	rarities.sort()
	rarities.reverse()
	for rarity: int in rarities:
		_add_row(loot_list, "  " + CustomVariables.rarity_name(rarity),
			"x%d" % tally.equipment_by_rarity[rarity], CustomVariables.rarity_color(rarity))
	if tally.best_equipment:
		var best: EquipmentData = tally.best_equipment
		_add_row(loot_list, "Best: " + best.display_name, "", CustomVariables.rarity_color(best.rarity))

	_add_subheader(loot_list, "Treasure", COLOR_DIM)
	_add_row(loot_list, "Chests opened", str(tally.chests), COLOR_TEXT, chest_icon)
	_add_row(loot_list, "Schematics", str(tally.schematics), COLOR_TEXT, schematic_icon)

func _build_journey() -> void:
	_add_header(journey_list, "Journey")
	_add_row(journey_list, "Islands visited", str(tally.islands), COLOR_GOLD)

	var won: int = RunTally.total(tally.events_completed)
	var lost: int = RunTally.total(tally.events_failed)
	_add_subheader(journey_list, "Events", COLOR_DIM)
	if won + lost == 0:
		_add_empty(journey_list, "No events attempted.")
	for entry: Array in RunTally.sorted_entries(tally.events_completed):
		_add_row(journey_list, entry[0], "won x%d" % entry[1], COLOR_WON)
	for entry: Array in RunTally.sorted_entries(tally.events_failed):
		_add_row(journey_list, entry[0], "lost x%d" % entry[1], COLOR_LOST)

	_add_subheader(journey_list, "Destroyed", COLOR_DIM)
	if tally.objects.is_empty():
		_add_empty(journey_list, "Left everything standing.")
	for entry: Array in RunTally.sorted_entries(tally.objects):
		_add_row(journey_list, entry[0], "x%d" % entry[1])

# --- Widgets ----------------------------------------------------------------------

func _add_tile(caption: String, value: int, color: Color, formatter: Callable = Callable()) -> void:
	if not formatter.is_valid():
		formatter = func(v: int) -> String: return str(v)
	var tile: PanelContainer = PanelContainer.new()
	tile.theme_type_variation = &"RowPanel"
	tile.custom_minimum_size = Vector2(170, 0)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 0)
	tile.add_child(box)

	var value_label: Label = Label.new()
	value_label.text = formatter.call(value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override(&"font_size", TILE_VALUE_FONT_SIZE)
	value_label.add_theme_color_override(&"font_color", color)
	box.add_child(value_label)

	var caption_label: Label = Label.new()
	caption_label.text = caption.to_upper()
	caption_label.theme_type_variation = &"DimLabel"
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_size_override(&"font_size", TILE_CAPTION_FONT_SIZE)
	box.add_child(caption_label)

	tile.set_meta(&"value_label", value_label)
	tile.set_meta(&"target", value)
	tile.set_meta(&"formatter", formatter)
	summary.add_child(tile)
	_tiles.append(tile)

func _add_header(list: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = &"HeaderLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", HEADER_FONT_SIZE)
	_track_row(list, label)
	var line: HSeparator = HSeparator.new()
	_track_row(list, line)

func _add_subheader(list: VBoxContainer, text: String, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override(&"font_size", TILE_CAPTION_FONT_SIZE)
	label.add_theme_color_override(&"font_color", color)
	# Breathing room above each group.
	label.custom_minimum_size = Vector2(0, 26)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_track_row(list, label)

func _add_row(list: VBoxContainer, label_text: String, value_text: String,
		color: Color = COLOR_TEXT, icon: Texture2D = null) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	if icon:
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = ICON_SIZE
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon_rect)

	var name_label: Label = Label.new()
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	name_label.add_theme_color_override(&"font_color", color)
	row.add_child(name_label)

	if not value_text.is_empty():
		var value_label: Label = Label.new()
		value_label.text = value_text
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
		value_label.add_theme_color_override(&"font_color", COLOR_GOLD if color == COLOR_TEXT else color)
		row.add_child(value_label)

	_track_row(list, row)

func _add_empty(list: VBoxContainer, text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	label.theme_type_variation = &"DimLabel"
	label.add_theme_font_size_override(&"font_size", ROW_FONT_SIZE)
	_track_row(list, label)

## Adds a row to a column; its position in the column sets when it fades in.
func _track_row(list: VBoxContainer, row: Control) -> void:
	row.set_meta(&"order", list.get_child_count())
	list.add_child(row)
	_rows.append(row)

static func _item_name(item: CustomVariables.items) -> String:
	match item:
		CustomVariables.items.SKYSHARD:
			return "Skyshards"
		CustomVariables.items.COLOR_SCROLL:
			return "Color Scrolls"
		CustomVariables.items.ESSENCE:
			return "Essence"
		CustomVariables.items.WOOD:
			return "Wood"
	return CustomVariables.items.keys()[item].capitalize() + "s"

func _format_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d" % [seconds / 60, seconds % 60]
