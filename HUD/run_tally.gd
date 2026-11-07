class_name RunTally extends RefCounted
## Counts what happened during one run, for the death screen.
## Listens to EventBus only. A run starts when the player enters a rift from the hub
## and ends when they're back in the hub; anything that happens in the hub isn't counted.

var enemies: Dictionary[String, int] = {}
## Bosses fought outside a boss arena (apple boss, bird boss events).
var elites: Dictionary[String, int] = {}
## Biome bosses, fought in a boss arena.
var bosses: Dictionary[String, int] = {}
var resources: Dictionary[CustomVariables.items, int] = {}
## Key: rounded rarity index.
var equipment_by_rarity: Dictionary[int, int] = {}
var best_equipment: EquipmentData = null
var objects: Dictionary[String, int] = {}
var events_completed: Dictionary[String, int] = {}
var events_failed: Dictionary[String, int] = {}
var islands: int = 0
var chests: int = 0
var schematics: int = 0

## True outside the hub. Starts true so test scenes without a hub still count.
var _in_run: bool = true
var _start_msec: int = 0
var _end_msec: int = -1

func _init() -> void:
	reset()
	EventBus.entered_rift.connect(_on_event_bus_entered_rift)
	EventBus.in_main_menu.connect(_on_event_bus_in_main_menu)
	EventBus.enemy_died.connect(_on_event_bus_enemy_died)
	EventBus.equipment_dropped.connect(_on_event_bus_equipment_dropped)
	EventBus.resource_collected.connect(_on_event_bus_resource_collected)
	EventBus.object_destroyed.connect(_on_event_bus_object_destroyed)
	EventBus.chest_opened.connect(_on_event_bus_chest_opened)
	EventBus.schematic_found.connect(_on_event_bus_schematic_found)
	EventBus.island_stepped_on.connect(_on_event_bus_island_stepped_on)
	EventBus.rift_event_finished.connect(_on_event_bus_rift_event_finished)

func reset() -> void:
	enemies.clear()
	elites.clear()
	bosses.clear()
	resources.clear()
	equipment_by_rarity.clear()
	best_equipment = null
	objects.clear()
	events_completed.clear()
	events_failed.clear()
	islands = 0
	chests = 0
	schematics = 0
	_start_msec = Time.get_ticks_msec()
	_end_msec = -1

## Freezes the run timer. Called when the run ends.
func finish() -> void:
	if _end_msec < 0:
		_end_msec = Time.get_ticks_msec()

func get_run_seconds() -> int:
	var end: int = _end_msec if _end_msec >= 0 else Time.get_ticks_msec()
	@warning_ignore("integer_division")
	return maxi(end - _start_msec, 0) / 1000

func get_equipment_total() -> int:
	return total(equipment_by_rarity)

static func total(counts: Dictionary) -> int:
	var sum: int = 0
	for key: Variant in counts:
		sum += int(counts[key])
	return sum

## [name, count] pairs, highest count first.
static func sorted_entries(counts: Dictionary[String, int]) -> Array[Array]:
	var entries: Array[Array] = []
	for key: String in counts:
		entries.append([key, counts[key]])
	entries.sort_custom(func(a: Array, b: Array) -> bool:
		return a[1] > b[1] if a[1] != b[1] else String(a[0]) < String(b[0]))
	return entries

## "res://Enemies/Balloon/BalloonEnemy.tscn" → "Balloon", "blue_flying_apple.tres" → "Blue Flying Apple".
static func pretty_name(raw: String) -> String:
	var words: String = raw.get_file().get_basename().capitalize()
	var trailing_number: RegEx = RegEx.create_from_string("\\s*\\d+$")
	words = trailing_number.sub(words, "")
	for suffix: String in [" Enemy", " Event"]:
		if words.ends_with(suffix):
			words = words.trim_suffix(suffix)
	return words if not words.is_empty() else "Unknown"

static func enemy_name(enemy: Enemy) -> String:
	var data: EnemyData = enemy.stats
	if data:
		if not data.display_name.is_empty():
			return data.display_name
		if data.resource_path.ends_with(".tres"):
			return pretty_name(data.resource_path)
	if not enemy.scene_file_path.is_empty():
		return pretty_name(enemy.scene_file_path)
	return pretty_name(enemy.name)

static func _add(counts: Dictionary[String, int], key: String, amount: int = 1) -> void:
	counts[key] = counts.get(key, 0) + amount

# --- Run lifetime -------------------------------------------------------------

func _on_event_bus_entered_rift() -> void:
	if _in_run:
		return
	_in_run = true
	reset()

func _on_event_bus_in_main_menu() -> void:
	_in_run = false

# --- Counting -------------------------------------------------------------------

func _on_event_bus_enemy_died(enemy: Enemy) -> void:
	if not _in_run or not is_instance_valid(enemy):
		return
	# Event targets, not enemies; their events are counted on their own.
	if enemy is FlyingTarget or enemy is GoldenApple:
		return
	var enemy_label: String = enemy_name(enemy)
	var boss: Boss = enemy as Boss
	if boss == null:
		_add(enemies, enemy_label)
	elif boss.arena != null:
		_add(bosses, enemy_label)
	else:
		_add(elites, enemy_label)

func _on_event_bus_equipment_dropped(data: EquipmentData, _position: Vector2, existing: Equipment) -> void:
	# Existing equipment is the player's own item being swapped out, not a find.
	if not _in_run or data == null or existing != null:
		return
	var rarity: int = roundi(data.rarity)
	equipment_by_rarity[rarity] = equipment_by_rarity.get(rarity, 0) + 1
	if best_equipment == null or data.rarity > best_equipment.rarity:
		best_equipment = data

func _on_event_bus_resource_collected(item: CustomVariables.items, amount: int) -> void:
	if not _in_run:
		return
	resources[item] = resources.get(item, 0) + amount

func _on_event_bus_object_destroyed(object: GameObject) -> void:
	if not _in_run:
		return
	var object_label: String = object.display_name
	if object_label.is_empty():
		object_label = pretty_name(object.scene_file_path if not object.scene_file_path.is_empty() else String(object.name))
	_add(objects, object_label)

func _on_event_bus_chest_opened(_chest: Chest) -> void:
	if _in_run:
		chests += 1

func _on_event_bus_schematic_found() -> void:
	if _in_run:
		schematics += 1

func _on_event_bus_island_stepped_on(_island: Island) -> void:
	if _in_run:
		islands += 1

func _on_event_bus_rift_event_finished(event: Event, success: bool) -> void:
	if not _in_run:
		return
	var event_label: String = event.get_display_name()
	if event_label.is_empty():
		event_label = pretty_name(event.scene_file_path if not event.scene_file_path.is_empty() else String(event.name))
	_add(events_completed if success else events_failed, event_label)
