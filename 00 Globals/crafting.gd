extends Node
## Autoload as "Crafting". Owns schematics and known recipes, and the one-craft-per-run flag.
## Schematics are picked up unidentified in rifts; the spirit reveals them into known recipes;
## the blacksmith crafts known recipes.

signal schematics_changed
signal recipe_learned(template: EquipmentData)
signal crafted(template: EquipmentData)
signal craft_lock_changed(locked: bool)

const SAVE_SECTION: StringName = &"crafting"
## Every equipment template that can be learned comes from these pools.
const POOL_PATHS: Array[String] = [
	"res://Items/LootManager/ItemPools/bow_pool.tres",
	"res://Items/LootManager/ItemPools/arrow_pool.tres",
	"res://Items/LootManager/ItemPools/ring_pool.tres",
]

const SCHEMATIC_SCENE: String = "res://Items/Other/Schematic/Schematic.tscn"
## Drop chance (%) for enemies and chests that don't set their own override.
const BASE_SCHEMATIC_CHANCE: float = 2.0
const BLACKSMITH_ID: StringName = &"blacksmith"

## Every craft costs this many Skyshards, plus the slot's material.
const CRAFT_SKYSHARDS: int = 1
## Second craft material per slot. Keys are EquipmentData.slots (BOW, ARROW, RING).
const CRAFT_MATERIALS: Dictionary[int, CustomVariables.items] = {
	0: CustomVariables.items.WOOD,
	1: CustomVariables.items.COIN,
	2: CustomVariables.items.ESSENCE,
}

## Picked up but not yet revealed by the spirit.
var unidentified: int = 0
## Template resource paths of learned recipes. Saved as-is.
var known: Array[String] = []
## One craft per run. Reset by a death (falling in the hub doesn't kill) or by loading a game.
var crafted_this_run: bool = false:
	set(value):
		if value == crafted_this_run:
			return
		crafted_this_run = value
		craft_lock_changed.emit(value)

# Loaded lazily with load(): templates pull in ability scripts that depend on Player,
# which would put this autoload in a compile-order cycle.
var _templates: Array[EquipmentData] = []

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)
	EventBus.player_died.connect(_on_event_bus_player_died)

# --- Recipes --------------------------------------------------------------

func get_all_templates() -> Array[EquipmentData]:
	if _templates.is_empty():
		for path: String in POOL_PATHS:
			var pool: ItemPool = load(path) as ItemPool
			if pool == null:
				push_warning("Crafting: missing item pool %s" % path)
				continue
			for template: EquipmentData in pool.templates:
				if template and not _templates.has(template):
					_templates.append(template)
	return _templates

func knows(template: EquipmentData) -> bool:
	return known.has(template.resource_path)

func get_known_templates() -> Array[EquipmentData]:
	return get_all_templates().filter(func(t: EquipmentData) -> bool: return knows(t))

func get_unknown_templates() -> Array[EquipmentData]:
	return get_all_templates().filter(func(t: EquipmentData) -> bool: return not knows(t))

func get_craft_cost(template: EquipmentData) -> Dictionary[CustomVariables.items, int]:
	var cost: Dictionary[CustomVariables.items, int] = {
		CustomVariables.items.SKYSHARD: CRAFT_SKYSHARDS,
	}
	cost[CRAFT_MATERIALS[template.slot]] = template.craft_material_amount
	return cost

func can_craft(template: EquipmentData, player: Player) -> bool:
	return not crafted_this_run and knows(template) \
		and MetaProgress.can_pay(get_craft_cost(template), player.stats)

## Pays, locks crafting until the next death, and drops the item (Common) at drop_position.
func craft(template: EquipmentData, player: Player, drop_position: Vector2) -> bool:
	if not can_craft(template, player):
		return false
	var cost: Dictionary[CustomVariables.items, int] = get_craft_cost(template)
	for item: CustomVariables.items in cost:
		player.buy(cost[item], item)
	crafted_this_run = true
	SaveService.save_game()
	EventBus.drop_specific_item.emit(template, drop_position, 0)
	crafted.emit(template)
	return true

func _on_event_bus_player_died(_death_screen: bool) -> void:
	crafted_this_run = false

# --- Schematics -----------------------------------------------------------

## False until the blacksmith is built, and once every unknown recipe already has a schematic waiting,
## so no drop is ever a duplicate.
func can_drop_schematic() -> bool:
	if not MetaProgress.is_built(BLACKSMITH_ID):
		return false
	return get_unknown_templates().size() > unidentified

## Rolls a schematic drop. A negative override uses BASE_SCHEMATIC_CHANCE.
func try_drop_schematic(position: Vector2, chance_override: float = -1.0) -> void:
	var chance: float = chance_override if chance_override >= 0.0 else BASE_SCHEMATIC_CHANCE
	if not can_drop_schematic() or randf_range(0.0, 100.0) >= chance:
		return
	# Node2D, not Item: naming Item here would pull Player into this autoload's compile chain.
	var schematic: Node2D = load(SCHEMATIC_SCENE).instantiate() as Node2D
	EventBus.summon_effect.emit(schematic)
	schematic.global_position = position
	schematic.call(&"launch", position)

func add_schematic() -> void:
	unidentified += 1
	SaveService.save_game()
	schematics_changed.emit()

func has_unidentified() -> bool:
	return unidentified > 0

## Reveals every waiting schematic into a distinct unknown recipe. Returns the learned templates.
func identify_all() -> Array[EquipmentData]:
	var remaining: Array[EquipmentData] = get_unknown_templates()
	var learned: Array[EquipmentData] = []
	while unidentified > 0 and not remaining.is_empty():
		var template: EquipmentData = remaining.pick_random()
		remaining.erase(template)
		known.append(template.resource_path)
		learned.append(template)
		unidentified -= 1
	unidentified = 0
	SaveService.save_game()
	for template: EquipmentData in learned:
		recipe_learned.emit(template)
	schematics_changed.emit()
	return learned

# --- Save / load ----------------------------------------------------------

func _save() -> Dictionary:
	return {
		"unidentified": unidentified,
		"known": known.duplicate(),
	}

## Unknown paths (moved or deleted items) are skipped, so removing an item never breaks a save.
func _load(data: Dictionary) -> void:
	unidentified = int(data.get("unidentified", 0))
	# Not saved: loading a game always starts with the forge available.
	crafted_this_run = false
	known.clear()
	for raw: Variant in data.get("known", []):
		var path: String = str(raw)
		if ResourceLoader.exists(path):
			known.append(path)
		else:
			push_warning("Crafting: unknown recipe '%s'" % path)
	schematics_changed.emit()
