extends Node
## Autoload as "SaveService". The only thing that reads or writes the save file.
## Systems register a named section with a getter (returns a Dictionary to save)
## and a setter (receives that Dictionary on load). The service never needs to
## know what the data means.

signal saved
signal loaded

const SAVE_PATH: String = "user://save.json"
const TEMP_PATH: String = "user://save.json.tmp"
const BAD_PATH: String = "user://save.json.bad"
## Bump this whenever the saved format changes, and add a step to _migrate().
const SAVE_VERSION: int = 1

var _getters: Dictionary[StringName, Callable] = {}
var _setters: Dictionary[StringName, Callable] = {}
## Last data read from or written to disk, per section. Sections whose owner
## isn't registered right now (e.g. a hub system while in a rift) are kept as-is.
var _sections: Dictionary = {}

func _ready() -> void:
	load_game()

## Call from the owning system's _ready(). The setter is called right away with
## this section's saved data, or an empty Dictionary if there is none yet.
func register(section: StringName, getter: Callable, setter: Callable) -> void:
	_getters[section] = getter
	_setters[section] = setter
	setter.call(_sections.get(String(section), {}))

func unregister(section: StringName) -> void:
	_getters.erase(section)
	_setters.erase(section)

func save_game() -> void:
	for section: StringName in _getters:
		var getter: Callable = _getters[section]
		if getter.is_valid():
			_sections[String(section)] = getter.call()

	var data: Dictionary = {
		"version": SAVE_VERSION,
		"sections": _sections,
	}
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: can't write temp save (%s)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# Swap the finished temp file in, so a crash mid-write can't corrupt the real save.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var err: Error = DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	if err != OK:
		push_error("SaveService: can't replace save file (%s)" % error_string(err))
		return
	saved.emit()

func load_game() -> void:
	_sections = {}
	if not FileAccess.file_exists(SAVE_PATH):
		loaded.emit()
		return

	var text: String = FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_error("SaveService: save file is corrupt, moved to %s" % BAD_PATH)
		DirAccess.rename_absolute(SAVE_PATH, BAD_PATH)
		loaded.emit()
		return

	var data: Dictionary = _migrate(parsed)
	_sections = data.get("sections", {})

	for section: StringName in _setters:
		var setter: Callable = _setters[section]
		if setter.is_valid():
			setter.call(_sections.get(String(section), {}))
	loaded.emit()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Deletes the save and tells every registered system to reset.
## Each setter receives an empty Dictionary and should fall back to defaults.
func new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_sections = {}
	for section: StringName in _setters:
		var setter: Callable = _setters[section]
		if setter.is_valid():
			setter.call({})
	loaded.emit()

func _migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 1))
	# Add one step per format change, e.g.:
	# if version == 1:
	# 	data["sections"]["upgrades"] = {}
	# 	version = 2
	data["version"] = version
	return data
