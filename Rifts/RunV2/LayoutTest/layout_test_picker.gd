class_name LayoutTestPicker extends CanvasLayer
## Debug panel for testing a combat layout: pick a layout (every scene in LAYOUT_DIR), its
## enemies (Random roll, Empty, or one encounter set from ENCOUNTER_DIR) and the biome.
## Pauses the game while open.

const LAYOUT_DIR: String = "res://Rifts/RunV2/CombatRift/Layouts/"
const ENCOUNTER_DIR: String = "res://Rifts/RunV2/Encounters/Resource/"
const BIOMES: Array[String] = ["Dirt", "Snow", "Hell"]
const RANDOM_LABEL: String = "Random"
const EMPTY_LABEL: String = "Empty (no enemies)"

var _layouts: Array[String] = []
var _encounters: Array[EncounterSet] = []
var _layout_list: ItemList
var _encounter_list: ItemList
var _biome_list: ItemList


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(8, 8)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "Layout test"
	column.add_child(title)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	_layout_list = _add_list(row, "Layout", Vector2(140, 160))
	for path: String in _scan(LAYOUT_DIR, ".tscn"):
		_layouts.append(path)
		_layout_list.add_item(path.get_file().trim_suffix(".tscn"))
	_encounter_list = _add_list(row, "Enemies", Vector2(160, 160))
	_encounter_list.add_item(RANDOM_LABEL)
	_encounter_list.add_item(EMPTY_LABEL)
	for path: String in _scan(ENCOUNTER_DIR, ".tres"):
		var encounter: EncounterSet = load(path) as EncounterSet
		if encounter:
			_encounters.append(encounter)
			_encounter_list.add_item(encounter.display_name if encounter.display_name != "" else path.get_file())
	_biome_list = _add_list(row, "Biome", Vector2(60, 160))
	for biome: String in BIOMES:
		_biome_list.add_item(biome)
	if _layout_list.item_count > 0:
		_layout_list.select(0)
	_encounter_list.select(0)
	_biome_list.select(0)
	var buttons: HBoxContainer = HBoxContainer.new()
	column.add_child(buttons)
	var go: Button = Button.new()
	go.text = "Play"
	go.pressed.connect(_on_go_pressed)
	buttons.add_child(go)
	var cancel: Button = Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_close)
	buttons.add_child(cancel)


func _add_list(parent: Control, heading: String, min_size: Vector2) -> ItemList:
	var box: VBoxContainer = VBoxContainer.new()
	parent.add_child(box)
	var label: Label = Label.new()
	label.text = heading
	box.add_child(label)
	var list: ItemList = ItemList.new()
	list.custom_minimum_size = min_size
	box.add_child(list)
	return list


## Files in dir with the extension, sorted by name.
func _scan(dir: String, extension: String) -> Array[String]:
	var names: Array[String] = []
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(extension):
			names.append(file)
	names.sort()
	var paths: Array[String] = []
	for file: String in names:
		paths.append(dir + file)
	return paths


func _on_go_pressed() -> void:
	var layout_index: int = _first_selected(_layout_list)
	if layout_index < 0:
		return
	var layout: PackedScene = load(_layouts[layout_index]) as PackedScene
	var encounter_index: int = _first_selected(_encounter_list)
	var empty: bool = encounter_index == 1
	var encounter: EncounterSet = _encounters[encounter_index - 2] if encounter_index >= 2 else null
	var biome: int = maxi(_first_selected(_biome_list), 0)
	_close()
	EventBus.layout_test_requested.emit(layout, encounter, empty, biome)


func _first_selected(list: ItemList) -> int:
	var selected: PackedInt32Array = list.get_selected_items()
	return selected[0] if not selected.is_empty() else -1


func _close() -> void:
	get_tree().paused = false
	queue_free()
