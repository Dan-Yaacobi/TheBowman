class_name LayoutTestSpawnPanel extends CanvasLayer
## Layout test only: F2 toggles a list of every EnemyEntry. Clicking one spawns it awake:
## flyers near the player, ground enemies on the island nearest the player. These don't count
## toward unlocking the exit (the encounter director doesn't own them).

const ENTRY_DIR: String = "res://Rifts/RiftEnemySpawner/EnemyEntry/"
## Flyers appear this far from the player (x is randomly flipped).
const FLYER_OFFSET: Vector2 = Vector2(120.0, -60.0)

var _panel: PanelContainer
var _count_label: Label
var _spawned: Array[Enemy] = []


func _ready() -> void:
	layer = 50
	_build()
	_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F2:
		_panel.visible = not _panel.visible
		get_viewport().set_input_as_handled()


func spawn_entry(entry: EnemyEntry) -> void:
	var enemy: Enemy = entry.get_factory().call()
	if enemy == null:
		return
	enemy.global_position = _spawn_position(entry)
	_spawned.append(enemy)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
	EventBus.enemy_summoned.emit(enemy)
	_update_count()


func _spawn_position(entry: EnemyEntry) -> Vector2:
	var player_pos: Vector2 = PlayerManager.player.global_position
	var ground: bool = entry.spawn_zone == SpawnHandler.Zone.ISLAND or entry.spawn_zone == SpawnHandler.Zone.ISLAND_CENTER
	if ground:
		var island: Island = _nearest_island(player_pos)
		if island:
			return island.get_top_center() + Vector2(0, -12)
	var offset: Vector2 = FLYER_OFFSET
	if randf() < 0.5:
		offset.x = -offset.x
	return player_pos + offset


func _nearest_island(from: Vector2) -> Island:
	var best: Island = null
	var best_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group(Island.GROUP):
		var island: Island = node as Island
		if island == null or not island.is_solid():
			continue
		var distance: float = island.global_position.distance_to(from)
		if distance < best_distance:
			best_distance = distance
			best = island
	return best


func _clear_enemies() -> void:
	for enemy: Enemy in _spawned.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned.clear()
	_update_count()


func _on_enemy_tree_exited(enemy: Enemy) -> void:
	_spawned.erase(enemy)
	_update_count()


func _build() -> void:
	var hint: Label = Label.new()
	hint.text = "Layout test  -  F2: spawn enemies"
	hint.position = Vector2(8, 4)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 3)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	_panel = PanelContainer.new()
	_panel.position = Vector2(8, 18)
	add_child(_panel)
	var column: VBoxContainer = VBoxContainer.new()
	_panel.add_child(column)
	_count_label = Label.new()
	column.add_child(_count_label)
	var clear: Button = Button.new()
	clear.text = "Clear spawned"
	clear.focus_mode = Control.FOCUS_NONE
	clear.pressed.connect(_clear_enemies)
	column.add_child(clear)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(150, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for entry: EnemyEntry in _load_entries():
		var button: Button = Button.new()
		button.text = _entry_name(entry)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(spawn_entry.bind(entry))
		list.add_child(button)
	_update_count()


func _update_count() -> void:
	if _count_label:
		_count_label.text = "Spawned alive: %d" % _spawned.size()


func _load_entries() -> Array[EnemyEntry]:
	var entries: Array[EnemyEntry] = []
	var names: Array[String] = []
	for file: String in ResourceLoader.list_directory(ENTRY_DIR):
		if file.ends_with(".tres"):
			names.append(file)
	names.sort()
	for file: String in names:
		var entry: EnemyEntry = load(ENTRY_DIR + file) as EnemyEntry
		if entry and entry.scene:
			entries.append(entry)
	return entries


func _entry_name(entry: EnemyEntry) -> String:
	if entry.data and not entry.data.display_name.is_empty():
		return entry.data.display_name
	return entry.resource_path.get_file().trim_suffix(".tres").trim_suffix("_entry").replace("_", " ").capitalize()
