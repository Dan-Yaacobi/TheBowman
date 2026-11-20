class_name EnemyTestEvent extends Event
## Dev room for trying out enemies. A panel lists every EnemyEntry in ENTRY_DIR; clicking one
## spawns it (island enemies on a floating island, flyers near the player). Falls are free here.
## Reached through the debug-only portal in the hub.

const ENTRY_DIR: String = "res://Rifts/RiftEnemySpawner/EnemyEntry/"
## Flyers appear this far from the player (x is randomly flipped).
const FLYER_OFFSET: Vector2 = Vector2(160.0, -80.0)

@onready var spawn_islands: Node2D = $SpawnIslands

var _spawned: Array[Enemy] = []
var _count_label: Label


func _ready() -> void:
	_build_panel()


func on_event_exited() -> void:
	_clear_enemies()


# --- Spawning ---

func spawn_entry(entry: EnemyEntry) -> void:
	var enemy: Enemy = entry.get_factory().call()
	if enemy == null:
		return
	# Not in the tree yet: the world adds it (enemy_summoned) at this global position
	enemy.global_position = _spawn_position(entry)
	_spawned.append(enemy)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
	EventBus.enemy_summoned.emit(enemy)
	_update_count()


func _spawn_position(entry: EnemyEntry) -> Vector2:
	var player: Node2D = PlayerManager.player
	if entry.spawn_zone == SpawnHandler.Zone.ISLAND_CENTER:
		var islands: Array[Node] = spawn_islands.get_children()
		islands.shuffle()
		for node: Node in islands:
			var island: Island = node as Island
			if island and island.has_free_center_spot():
				return island.claim_center_spot()
		return (islands[0] as Island).get_top_center()
	if entry.spawn_zone == SpawnHandler.Zone.ISLAND:
		var islands: Array[Node] = spawn_islands.get_children()
		islands.shuffle()
		for node: Node in islands:
			var island: Island = node as Island
			if island and island.has_free_object_spot():
				return island.claim_object_spot()
		# Every spot taken: stack on a random island's top
		var fallback: Island = islands[0] as Island
		return fallback.get_top_center()
	var offset: Vector2 = FLYER_OFFSET
	if randf() < 0.5:
		offset.x = -offset.x
	return player.global_position + offset


func _clear_enemies() -> void:
	for enemy: Enemy in _spawned.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned.clear()
	_update_count()


func _on_enemy_tree_exited(enemy: Enemy) -> void:
	_spawned.erase(enemy)
	_update_count()


# --- Panel ---

func _build_panel() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(8, 8)
	layer.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "Enemy test"
	column.add_child(title)
	_count_label = Label.new()
	column.add_child(_count_label)
	var clear: Button = Button.new()
	clear.text = "Clear all"
	clear.focus_mode = Control.FOCUS_NONE
	clear.pressed.connect(_clear_enemies)
	column.add_child(clear)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(150, 220)
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
		_count_label.text = "Alive: %d" % _spawned.size()


## Every EnemyEntry resource in ENTRY_DIR, sorted by file name.
func _load_entries() -> Array[EnemyEntry]:
	var entries: Array[EnemyEntry] = []
	var files: PackedStringArray = ResourceLoader.list_directory(ENTRY_DIR)
	var names: Array[String] = []
	for file: String in files:
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
