extends Node
## Autoload as "SaveService". The only thing that reads or writes save files.
## Systems register a named section with a getter (returns a Dictionary to save)
## and a setter (receives that Dictionary on load). The service never needs to
## know what the data means.
##
## Saves live in SLOT_COUNT slots. One slot is active at a time; the start menu
## picks it with select_slot(). Until then the last-played slot is active, so
## running the game scene directly still loads something sensible.

signal saved
signal loaded
signal slot_deleted(slot: int)

const SLOT_COUNT: int = 3
const SLOT_PATH: String = "user://save_slot_%d.json"
const TEMP_SUFFIX: String = ".tmp"
const BAD_SUFFIX: String = ".bad"
## Single save from before slots existed. Moved into slot 0 on first launch.
const LEGACY_PATH: String = "user://save.json"
## Remembers the last-played slot between launches.
const SLOTS_CONFIG_PATH: String = "user://save_slots.cfg"
## Bump this whenever the saved format changes, and add a step to _migrate().
const SAVE_VERSION: int = 1

var active_slot: int = 0

var _getters: Dictionary[StringName, Callable] = {}
var _setters: Dictionary[StringName, Callable] = {}
## Last data read from or written to disk, per section. Sections whose owner
## isn't registered right now (e.g. a hub system while in a rift) are kept as-is.
var _sections: Dictionary = {}
## Seconds played in this slot as of the last load or save.
var _playtime: float = 0.0
## Ticks (ms) when _playtime was last brought up to date.
var _playtime_mark_ms: int = 0
## True while setters run. Saves requested by a setter wait until every section
## is loaded, so a half-loaded slot can't be written over another slot's data.
var _loading: bool = false
var _save_after_load: bool = false

func _ready() -> void:
	_migrate_legacy_save()
	active_slot = get_last_slot()
	load_game()

# --- Slots ----------------------------------------------------------------

## Makes `slot` the active slot and loads it. An empty slot loads as a new game.
func select_slot(slot: int) -> void:
	active_slot = clampi(slot, 0, SLOT_COUNT - 1)
	var config: ConfigFile = ConfigFile.new()
	config.set_value("slots", "last", active_slot)
	config.save(SLOTS_CONFIG_PATH)
	load_game()

func get_last_slot() -> int:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SLOTS_CONFIG_PATH) != OK:
		return 0
	return clampi(int(config.get_value("slots", "last", 0)), 0, SLOT_COUNT - 1)

## The slot "Continue" should load: the last-played slot if it has a save,
## otherwise the most recently saved one. -1 when every slot is empty.
func get_continue_slot() -> int:
	if slot_exists(get_last_slot()):
		return get_last_slot()
	var best_slot: int = -1
	var best_time: int = -1
	for slot: int in SLOT_COUNT:
		var info: Dictionary = get_slot_info(slot)
		if info.is_empty():
			continue
		var saved_at: int = int(info.get("saved_at", 0))
		if saved_at > best_time:
			best_time = saved_at
			best_slot = slot
	return best_slot

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

## What the start menu shows for a slot, read straight from disk without loading it.
## Empty Dictionary = empty slot. Otherwise: "saved_at" (unix seconds), "playtime"
## (seconds), "sections" (raw saved data), and "corrupt" = true if it can't be read.
func get_slot_info(slot: int) -> Dictionary:
	var path: String = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {"corrupt": true}
	var data: Dictionary = _migrate(parsed)
	var info: Dictionary = data.get("info", {})
	return {
		"saved_at": int(info.get("saved_at", 0)),
		"playtime": float(info.get("playtime", 0.0)),
		"sections": data.get("sections", {}),
	}

## Erases a slot for good. If it's the active slot, every registered system resets.
func delete_slot(slot: int) -> void:
	var path: String = _slot_path(slot)
	for file_path: String in [path, path + TEMP_SUFFIX, path + BAD_SUFFIX]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)
	if slot == active_slot:
		_reset_loaded_data()
	slot_deleted.emit(slot)

# --- Sections -------------------------------------------------------------

## Call from the owning system's _ready(). The setter is called right away with
## this section's saved data, or an empty Dictionary if there is none yet.
func register(section: StringName, getter: Callable, setter: Callable) -> void:
	_getters[section] = getter
	_setters[section] = setter
	setter.call(_sections.get(String(section), {}))

func unregister(section: StringName) -> void:
	_getters.erase(section)
	_setters.erase(section)

# --- Save / load ----------------------------------------------------------

func save_game() -> void:
	if _loading:
		_save_after_load = true
		return
	for section: StringName in _getters:
		var getter: Callable = _getters[section]
		if getter.is_valid():
			_sections[String(section)] = getter.call()

	_update_playtime()
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"info": {
			"saved_at": int(Time.get_unix_time_from_system()),
			"playtime": _playtime,
		},
		"sections": _sections,
	}
	var path: String = _slot_path(active_slot)
	var temp_path: String = path + TEMP_SUFFIX
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: can't write temp save (%s)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# Swap the finished temp file in, so a crash mid-write can't corrupt the real save.
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var err: Error = DirAccess.rename_absolute(temp_path, path)
	if err != OK:
		push_error("SaveService: can't replace save file (%s)" % error_string(err))
		return
	saved.emit()

## Loads the active slot. An empty slot gives every system an empty Dictionary.
func load_game() -> void:
	_sections = {}
	_playtime = 0.0
	_playtime_mark_ms = Time.get_ticks_msec()
	var path: String = _slot_path(active_slot)
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			var data: Dictionary = _migrate(parsed)
			_sections = data.get("sections", {})
			var info: Dictionary = data.get("info", {})
			_playtime = float(info.get("playtime", 0.0))
		else:
			push_error("SaveService: save file is corrupt, moved to %s" % (path + BAD_SUFFIX))
			DirAccess.rename_absolute(path, path + BAD_SUFFIX)
	_call_setters()

func has_save() -> bool:
	return slot_exists(active_slot)

## Deletes the active slot's save and tells every registered system to reset.
## Each setter receives an empty Dictionary and should fall back to defaults.
func new_game() -> void:
	delete_slot(active_slot)

# --- Internals ------------------------------------------------------------

func _slot_path(slot: int) -> String:
	return SLOT_PATH % slot

func _reset_loaded_data() -> void:
	_sections = {}
	_playtime = 0.0
	_playtime_mark_ms = Time.get_ticks_msec()
	_call_setters()

func _call_setters() -> void:
	_loading = true
	_save_after_load = false
	for section: StringName in _setters:
		var setter: Callable = _setters[section]
		if setter.is_valid():
			setter.call(_sections.get(String(section), {}))
	_loading = false
	loaded.emit()
	if _save_after_load:
		_save_after_load = false
		save_game()

func _update_playtime() -> void:
	var now: int = Time.get_ticks_msec()
	_playtime += float(now - _playtime_mark_ms) / 1000.0
	_playtime_mark_ms = now

## Pre-slot saves become slot 0, so nobody loses progress when updating.
func _migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	if slot_exists(0):
		return
	var err: Error = DirAccess.rename_absolute(LEGACY_PATH, _slot_path(0))
	if err != OK:
		push_error("SaveService: can't move legacy save into slot 0 (%s)" % error_string(err))

func _migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 1))
	# Add one step per format change, e.g.:
	# if version == 1:
	# 	data["sections"]["upgrades"] = {}
	# 	version = 2
	data["version"] = version
	return data
