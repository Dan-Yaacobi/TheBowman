extends Node
## Autoload as "RunTracker". Records one run from start to end and emits EventBus.run_ended
## with a JSON-ready summary (later uploaded for analytics).
## A run starts when the player enters a rift from the hub and ends on death, a win,
## a return to the hub, or the game closing mid-run.
## Listens to EventBus only. Kill/loot counts come from a RunTally it owns.

const RESULT_DIED: String = "died"
const RESULT_WON: String = "won"
const RESULT_QUIT: String = "quit"
const RESULT_RETURNED: String = "returned_to_hub"
## Bumped when the summary layout changes, so the database can tell old rows apart.
const SUMMARY_VERSION: int = 2
const CAUSE_FALL: String = "Fall"
## Damage with no hurt box (poison, burn...).
const CAUSE_EFFECT: String = "Effect"

var tally: RunTally = RunTally.new()
var uploader: RunUploader

var _in_run: bool = false
var _run_id: String = ""
var _started_unix: int = 0
var _start_msec: int = 0
## Seconds of unpaused play. Menus, the death screen and scene fades don't count.
var _active_sec: float = 0.0

var _combat: Dictionary[String, int] = {}
var _movement: Dictionary[String, int] = {}
var _start_gear: Dictionary = {}
## Latest item per slot. Tracked as it changes: gear is already unequipped when player_died fires.
var _gear: Dictionary = {}
var _gear_changes: Array[Dictionary] = []
var _crafted_item: String = ""
var _meta_levels: Dictionary = {}
var _color_levels: Dictionary[String, int] = {}
var _active_ability: String = ""
var _active_ability_uses: int = 0
var _lore_found: int = 0
var _death_cause: String = ""
var _lowest_hp: int = 0
var _max_hp_start: int = 0
## Damage taken per source name.
var _damage_sources: Dictionary[String, int] = {}

var _rifts: Array[Dictionary] = []
var _current_rift: Dictionary = {}
var _bosses: Array[Dictionary] = []
var _current_boss: Dictionary = {}
var _current_boss_node: WeakRef = null

## Crafted in the hub, attached to the next run that starts.
var _pending_craft: String = ""

func _ready() -> void:
	uploader = RunUploader.new()
	uploader.name = "RunUploader"
	add_child(uploader)
	EventBus.entered_rift.connect(_on_event_bus_entered_rift)
	EventBus.in_main_menu.connect(_on_event_bus_in_main_menu)
	EventBus.player_died.connect(_on_event_bus_player_died)
	EventBus.run_won.connect(_on_event_bus_run_won)
	EventBus.entered_rift_portal.connect(_close_current_rift)
	EventBus.boss_portal_entered.connect(_close_current_rift)
	EventBus.boss_fight_started.connect(_on_event_bus_boss_fight_started)
	EventBus.enemy_died.connect(_on_event_bus_enemy_died)
	EventBus.arrow_released.connect(_on_event_bus_arrow_released)
	EventBus.arrow_enemy_hit.connect(_on_event_bus_arrow_enemy_hit)
	EventBus.arrow_missed.connect(_on_event_bus_arrow_missed)
	EventBus.sword_hit.connect(_on_event_bus_sword_hit)
	EventBus.enemy_stunned.connect(_on_event_bus_enemy_stunned)
	EventBus.enemy_frostbitten_hit.connect(_on_event_bus_enemy_frostbitten_hit)
	EventBus.dealt_bleed_damage.connect(_on_event_bus_dealt_bleed_damage)
	EventBus.poison_damage_dealt.connect(_on_event_bus_poison_damage_dealt)
	EventBus.leeched.connect(_on_event_bus_leeched)
	EventBus.dash_preformed.connect(_on_event_bus_dash_preformed)
	EventBus.jump_sound.connect(_on_event_bus_jump_sound)
	EventBus.player_fell.connect(_on_event_bus_player_fell)
	EventBus.player_heart_lost.connect(_on_event_bus_player_heart_lost)
	EventBus.player_damaged.connect(_on_event_bus_player_damaged)
	EventBus.player_healed.connect(_on_event_bus_player_healed)
	EventBus.potion_used.connect(_on_event_bus_potion_used)
	EventBus.enemy_damaged.connect(_on_event_bus_enemy_damaged)
	EventBus.equip_item.connect(_on_event_bus_equip_item)
	EventBus.active_ability_equipped.connect(_on_event_bus_active_ability_equipped)
	EventBus.active_ability_used.connect(_on_event_bus_active_ability_used)
	EventBus.color_level_changed.connect(_on_event_bus_color_level_changed)
	EventBus.lore_item_found.connect(_on_event_bus_lore_item_found)
	EventBus.rift_event_finished.connect(_on_event_bus_rift_event_finished)
	EventBus.chest_opened.connect(_on_event_bus_chest_opened)
	Crafting.crafted.connect(_on_crafting_crafted)

func _process(delta: float) -> void:
	if _in_run:
		_active_sec += delta

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _in_run:
		end_run(RESULT_QUIT)

func is_in_run() -> bool:
	return _in_run

# --- Run lifetime -----------------------------------------------------------------

func _start_run() -> void:
	_in_run = true
	_run_id = Crypto.new().generate_random_bytes(16).hex_encode()
	_started_unix = int(Time.get_unix_time_from_system())
	_start_msec = Time.get_ticks_msec()
	_active_sec = 0.0
	_death_cause = ""
	_damage_sources.clear()
	var player: Player = PlayerManager.player
	_max_hp_start = player.max_hp_value() if player else 0
	_lowest_hp = player.stats.hp if player else 0
	_combat.clear()
	_movement.clear()
	_gear_changes.clear()
	_color_levels.clear()
	_rifts.clear()
	_bosses.clear()
	_current_rift = {}
	_current_boss = {}
	_current_boss_node = null
	_active_ability = ""
	_active_ability_uses = 0
	_lore_found = 0
	_crafted_item = _pending_craft
	_pending_craft = ""
	_meta_levels = _snapshot_meta()
	_gear = _snapshot_gear()
	_start_gear = _gear.duplicate()

## Ends the current run and emits EventBus.run_ended. Safe to call when no run is active.
func end_run(result: String) -> void:
	if not _in_run:
		return
	_in_run = false
	_close_current_rift()
	if not _current_boss.is_empty():
		_close_current_boss(false)
	tally.finish()
	var summary: Dictionary = _build_summary(result)
	print("[RunTracker] run ended:\n", JSON.stringify(summary, "\t"))
	EventBus.run_ended.emit(summary)
	uploader.submit(summary)

func _on_event_bus_entered_rift() -> void:
	if not _in_run:
		_start_run()
	_close_current_rift()
	_open_rift()

func _on_event_bus_in_main_menu() -> void:
	# Death already ended the run; reaching the hub any other way counts as leaving it.
	end_run(RESULT_RETURNED)

func _on_event_bus_player_died(_death_screen: bool) -> void:
	end_run(RESULT_DIED)

func _on_event_bus_run_won() -> void:
	end_run(RESULT_WON)

func _on_crafting_crafted(template: EquipmentData) -> void:
	if template:
		_pending_craft = template.display_name

# --- Rifts and bosses -------------------------------------------------------------

func _open_rift() -> void:
	var biome: String = ""
	var rift: Rift = _current_world() as Rift
	if rift:
		biome = Rift.Type.keys()[rift.get_rift_type()]
	_current_rift = {
		"index": _rift_level(),
		"biome": biome,
		"started_sec": _elapsed_sec(),
		"duration_sec": 0,
		"kills": 0,
		"hits_taken": 0,
		"damage_taken": 0,
		"damage_dealt": 0,
		"falls": 0,
		"chests": 0,
		"events_completed": 0,
		"events_failed": 0,
	}

func _close_current_rift() -> void:
	if _current_rift.is_empty():
		return
	_current_rift["duration_sec"] = _elapsed_sec() - int(_current_rift["started_sec"])
	_rifts.append(_current_rift)
	_current_rift = {}

func _on_event_bus_boss_fight_started(boss: Boss) -> void:
	if not _in_run or not is_instance_valid(boss):
		return
	_close_current_rift()
	if not _current_boss.is_empty():
		_close_current_boss(false)
	_current_boss_node = weakref(boss)
	_current_boss = {
		"name": RunTally.enemy_name(boss),
		"after_rift": _rift_level(),
		"started_sec": _elapsed_sec(),
		"duration_sec": 0,
		"hits_taken": 0,
		"damage_taken": 0,
		"damage_dealt": 0,
		"falls": 0,
		"won": false,
	}

func _close_current_boss(won: bool) -> void:
	_current_boss["won"] = won
	_current_boss["duration_sec"] = _elapsed_sec() - int(_current_boss["started_sec"])
	_bosses.append(_current_boss)
	_current_boss = {}
	_current_boss_node = null

func _on_event_bus_enemy_died(enemy: Enemy) -> void:
	if not _in_run or not is_instance_valid(enemy):
		return
	if enemy is FlyingTarget or enemy is GoldenApple:
		return
	if not _current_boss.is_empty() and _current_boss_node and _current_boss_node.get_ref() == enemy:
		_close_current_boss(true)
		return
	_add_to_section(&"kills")

# --- Combat -------------------------------------------------------------------------

func _on_event_bus_arrow_released(shot_power: float) -> void:
	_count(_combat, "shots")
	if shot_power >= 1.0:
		_count(_combat, "perfect_shots")

func _on_event_bus_arrow_enemy_hit(perfect: bool, _arrow: Arrow, _target: Enemy) -> void:
	_count(_combat, "arrow_hits")
	if perfect:
		_count(_combat, "perfect_hits")

func _on_event_bus_arrow_missed() -> void:
	_count(_combat, "arrow_misses")

func _on_event_bus_sword_hit(_target: Node2D) -> void:
	_count(_combat, "sword_hits")

func _on_event_bus_enemy_stunned(_enemy: Enemy) -> void:
	_count(_combat, "stuns")

func _on_event_bus_enemy_frostbitten_hit(_enemy: Enemy) -> void:
	_count(_combat, "frostbite_hits")

func _on_event_bus_dealt_bleed_damage(amount: Variant, _entity: Variant = null) -> void:
	_count(_combat, "bleed_damage", int(amount))

func _on_event_bus_poison_damage_dealt() -> void:
	_count(_combat, "poison_ticks")

func _on_event_bus_leeched(amount: int, _position: Vector2) -> void:
	_count(_combat, "leech_heal", amount)

func _on_event_bus_player_damaged(amount: int, source: Node) -> void:
	if not _in_run:
		return
	_count(_combat, "hits_taken")
	_count(_combat, "damage_taken", amount)
	_add_to_section(&"hits_taken")
	_add_to_section(&"damage_taken", amount)
	var source_name: String = _source_name(source)
	_damage_sources[source_name] = _damage_sources.get(source_name, 0) + amount
	_death_cause = source_name
	if PlayerManager.player:
		_lowest_hp = mini(_lowest_hp, maxi(PlayerManager.player.stats.hp, 0))

func _on_event_bus_player_healed(amount: int) -> void:
	_count(_combat, "heals")
	_count(_combat, "hp_healed", amount)

func _on_event_bus_potion_used(heal_amount: int) -> void:
	_count(_combat, "potions_used")
	_count(_combat, "potion_heal", heal_amount)

func _on_event_bus_enemy_damaged(_enemy: Enemy, amount: int) -> void:
	_count(_combat, "damage_dealt", amount)
	_add_to_section(&"damage_dealt", amount)

# --- Movement -----------------------------------------------------------------------

func _on_event_bus_dash_preformed() -> void:
	_count(_movement, "dashes")

func _on_event_bus_jump_sound() -> void:
	_count(_movement, "jumps")

func _on_event_bus_player_fell(heart_lost: bool) -> void:
	if not _in_run:
		return
	_count(_movement, "falls")
	if heart_lost:
		_count(_movement, "falls_heart_lost")
		_death_cause = CAUSE_FALL
	_add_to_section(&"falls")

func _on_event_bus_player_heart_lost() -> void:
	_count(_movement, "hearts_lost")

# --- Build --------------------------------------------------------------------------

func _on_event_bus_equip_item(equip: Equipment) -> void:
	if not _in_run or equip == null or equip.data == null:
		return
	var entry: Dictionary = _item_entry(equip.data)
	_gear[entry["slot"]] = entry
	var change: Dictionary = entry.duplicate()
	change["rift"] = _rift_level()
	_gear_changes.append(change)

func _on_event_bus_active_ability_equipped(ability: ActiveAbility) -> void:
	if _in_run and ability:
		_active_ability = ability.name

func _on_event_bus_active_ability_used(_cooldown: float) -> void:
	if _in_run:
		_active_ability_uses += 1

func _on_event_bus_color_level_changed(color: CustomVariables.ItemColor, level: int) -> void:
	if _in_run:
		var key: String = CustomVariables.item_color_name(color)
		_color_levels[key] = maxi(_color_levels.get(key, 0), level)

func _on_event_bus_lore_item_found(_item: LoreItemData) -> void:
	if _in_run:
		_lore_found += 1

func _on_event_bus_rift_event_finished(_event: Event, success: bool) -> void:
	_add_to_section(&"events_completed" if success else &"events_failed")

func _on_event_bus_chest_opened(_chest: Chest) -> void:
	_add_to_section(&"chests")

# --- Summary ------------------------------------------------------------------------

func _build_summary(result: String) -> Dictionary:
	return {
		"summary_version": SUMMARY_VERSION,
		"run_id": _run_id,
		"game_version": _game_version(),
		"player_id": uploader.player_id,
		"build_type": uploader.build_type(),
		"platform": OS.get_name(),
		"started_at": Time.get_datetime_string_from_unix_time(_started_unix) + "Z",
		"ended_at": Time.get_datetime_string_from_system(true) + "Z",
		"duration_sec": _elapsed_sec(),
		"active_sec": roundi(_active_sec),
		"result": result,
		"death_cause": _death_cause if result == RESULT_DIED else "",
		"max_hp_start": _max_hp_start,
		"lowest_hp": _lowest_hp,
		"damage_taken_by_source": _damage_sources.duplicate(),
		"rift_reached": _rift_level(),
		"biome_reached": _rifts[-1]["biome"] if not _rifts.is_empty() else "",
		"bosses_killed": RunTally.total(tally.bosses),
		"combat": _combat.duplicate(),
		"movement": _movement.duplicate(),
		"kills": {
			"enemies": tally.enemies.duplicate(),
			"elites": tally.elites.duplicate(),
			"bosses": tally.bosses.duplicate(),
		},
		"economy": {
			"resources": _resource_names(tally.resources),
			"chests": tally.chests,
			"schematics": tally.schematics,
			"lore_items": _lore_found,
			"objects_destroyed": tally.objects.duplicate(),
			"equipment_found_by_rarity": _string_keys(tally.equipment_by_rarity),
		},
		"build": {
			"start_gear": _start_gear,
			"final_gear": _gear.duplicate(),
			"gear_changes": _gear_changes.duplicate(),
			"crafted_item": _crafted_item,
			"active_ability": _active_ability,
			"active_ability_uses": _active_ability_uses,
			"color_levels": _color_levels.duplicate(),
			"meta_levels": _meta_levels,
		},
		"islands_visited": tally.islands,
		"events_completed": tally.events_completed.duplicate(),
		"events_failed": tally.events_failed.duplicate(),
		"rifts": _rifts.duplicate(),
		"bosses": _bosses.duplicate(),
	}

## Readable name for whatever dealt damage: the enemy that owns the hurt box, else its scene.
func _source_name(source: Node) -> String:
	if source == null:
		return CAUSE_EFFECT
	var node: Node = source
	while node:
		if node is Enemy:
			return RunTally.enemy_name(node as Enemy)
		node = node.get_parent()
	node = source
	while node:
		if not node.scene_file_path.is_empty():
			return RunTally.pretty_name(node.scene_file_path)
		node = node.get_parent()
	return RunTally.pretty_name(source.name)

func _snapshot_gear() -> Dictionary:
	var gear: Dictionary = {}
	var player: Player = PlayerManager.player
	if player == null:
		return gear
	for data: EquipmentData in [player.stats.bow, player.stats.arrow, player.stats.ring]:
		if data:
			var entry: Dictionary = _item_entry(data)
			gear[entry["slot"]] = entry
	return gear

func _snapshot_meta() -> Dictionary:
	var levels: Dictionary = {}
	for key: StringName in MetaProgress.levels:
		levels[String(key)] = MetaProgress.levels[key]
	return levels

func _item_entry(data: EquipmentData) -> Dictionary:
	return {
		"slot": String(EquipmentData.slots.keys()[data.slot]).to_lower(),
		"name": data.display_name,
		"rarity": roundi(data.rarity),
	}

func _resource_names(counts: Dictionary[CustomVariables.items, int]) -> Dictionary:
	var out: Dictionary = {}
	for item: CustomVariables.items in counts:
		out[String(CustomVariables.items.keys()[item]).to_lower()] = counts[item]
	return out

func _string_keys(counts: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in counts:
		out[str(key)] = counts[key]
	return out

# --- Helpers ------------------------------------------------------------------------

func _count(section: Dictionary[String, int], key: String, amount: int = 1) -> void:
	if _in_run:
		section[key] = section.get(key, 0) + amount

## Adds to the open rift or boss record, whichever the player is in.
func _add_to_section(key: StringName, amount: int = 1) -> void:
	if not _in_run:
		return
	var section: Dictionary = _current_boss if not _current_boss.is_empty() else _current_rift
	if section.has(key):
		section[key] = int(section[key]) + amount

func _elapsed_sec() -> int:
	@warning_ignore("integer_division")
	return maxi(Time.get_ticks_msec() - _start_msec, 0) / 1000

func _rift_level() -> int:
	return PlayerManager.player.stats.rift_level if PlayerManager.player else 0

func _current_world() -> Node:
	return PlayerManager.player.get_parent() if PlayerManager.player else null

func _game_version() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	return version if not version.is_empty() else "unversioned"
