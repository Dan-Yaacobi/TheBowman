extends Node
## Autoload as "Lore". Owns which lore items were found and which the spirit explained.
## Carried items persist through death; explained ones never come back. Both are saved by id.

signal lore_changed

const SAVE_SECTION: StringName = &"lore"
const LIBRARY_PATH: String = "res://Items/Lore/Resource/lore_library.tres"

## Found but not yet explained, oldest first.
var carried: Array[StringName] = []
## Explained by the spirit, in order. Kept even if an item is removed from the library.
var explained: Array[StringName] = []

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

# --- Save / load ----------------------------------------------------------

func _save() -> Dictionary:
	return {
		"carried": _ids_to_strings(carried),
		"explained": _ids_to_strings(explained),
	}

## Carried ids missing from the library are dropped with a warning; explained ids are kept as-is.
func _load(data: Dictionary) -> void:
	carried.clear()
	explained.clear()
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

func _ids_to_strings(ids: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for id: StringName in ids:
		out.append(String(id))
	return out
