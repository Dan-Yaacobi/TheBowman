extends Node
## Autoload as "Lore". Owns which lore items were found and which the spirit explained,
## which after lines were heard, and the story flags that unlock them.
## Carried items persist through death; explained ones never come back. All saved by id.

signal lore_changed

const SAVE_SECTION: StringName = &"lore"
const LIBRARY_PATH: String = "res://Items/Lore/Resource/lore_library.tres"

## Found but not yet explained, oldest first.
var carried: Array[StringName] = []
## Explained by the spirit, in order. Kept even if an item is removed from the library.
var explained: Array[StringName] = []
## Explained items whose after lines the spirit has also told.
var after_heard: Array[StringName] = []
## Story moments that have happened (e.g. &"spirit_discovery", &"met_defector").
var flags: Array[StringName] = []

var _library: LoreLibrary

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)

func get_library() -> LoreLibrary:
	if _library == null:
		_library = load(LIBRARY_PATH) as LoreLibrary
		if _library == null:
			push_warning("Lore: missing library %s" % LIBRARY_PATH)
			_library = LoreLibrary.new()
	return _library

func find(id: StringName) -> LoreItemData:
	return get_library().find(id)

## True once picked up, carried or explained. Pickups use it so nothing is granted twice.
func has_found(id: StringName) -> bool:
	return carried.has(id) or explained.has(id)

## Not found yet and its requirement is met. Pickups (and later rift spawning) check this.
func can_obtain(item: LoreItemData) -> bool:
	return item != null and item.id != &"" and item.is_unlocked() and not has_found(item.id)

func is_explained(id: StringName) -> bool:
	return explained.has(id)

## Saved right away, like schematics. Returns false if it can't be obtained (found or gated).
func add(item: LoreItemData) -> bool:
	if not can_obtain(item):
		return false
	carried.append(item.id)
	SaveService.save_game()
	lore_changed.emit()
	return true

## Carried items, newest first.
func get_carried() -> Array[LoreItemData]:
	var out: Array[LoreItemData] = []
	for i: int in range(carried.size() - 1, -1, -1):
		var item: LoreItemData = find(carried[i])
		if item:
			out.append(item)
	return out

func mark_explained(item: LoreItemData) -> void:
	if item == null or is_explained(item.id):
		return
	carried.erase(item.id)
	explained.append(item.id)
	SaveService.save_game()
	lore_changed.emit()

## Explained items whose after lines are unlocked and not heard yet, newest explained first.
func get_after_pending() -> Array[LoreItemData]:
	var out: Array[LoreItemData] = []
	for i: int in range(explained.size() - 1, -1, -1):
		if after_heard.has(explained[i]):
			continue
		var item: LoreItemData = find(explained[i])
		if item and item.is_after_unlocked():
			out.append(item)
	return out

func mark_after_heard(item: LoreItemData) -> void:
	if item == null or after_heard.has(item.id):
		return
	after_heard.append(item.id)
	SaveService.save_game()
	lore_changed.emit()

# --- Story flags ------------------------------------------------------------

func has_flag(flag: StringName) -> bool:
	return flags.has(flag)

## Saved right away. Unlocks any after lines gated on this flag.
func set_flag(flag: StringName) -> void:
	if flag == &"" or flags.has(flag):
		return
	flags.append(flag)
	SaveService.save_game()
	lore_changed.emit()

# --- Save / load ----------------------------------------------------------

func _save() -> Dictionary:
	return {
		"carried": _ids_to_strings(carried),
		"explained": _ids_to_strings(explained),
		"after_heard": _ids_to_strings(after_heard),
		"flags": _ids_to_strings(flags),
	}

## Carried ids missing from the library are dropped with a warning; explained ids are kept as-is.
func _load(data: Dictionary) -> void:
	carried.clear()
	explained.clear()
	after_heard.clear()
	flags.clear()
	_append_unique(after_heard, data.get("after_heard", []))
	_append_unique(flags, data.get("flags", []))
	for raw: Variant in data.get("explained", []):
		var id: StringName = StringName(str(raw))
		if not explained.has(id):
			explained.append(id)
	for raw: Variant in data.get("carried", []):
		var id: StringName = StringName(str(raw))
		if find(id) == null:
			push_warning("Lore: unknown lore item '%s'" % id)
			continue
		if not has_found(id):
			carried.append(id)
	lore_changed.emit()

func _append_unique(target: Array[StringName], raw_ids: Variant) -> void:
	if not raw_ids is Array:
		return
	for raw: Variant in raw_ids:
		var id: StringName = StringName(str(raw))
		if not target.has(id):
			target.append(id)

func _ids_to_strings(ids: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for id: StringName in ids:
		out.append(String(id))
	return out
