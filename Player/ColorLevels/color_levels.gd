class_name ColorLevels extends Node
## Run-only color levels (Precision, Tempo, Elemental). Separate from MetaProgress.
## Each level makes items of that color stronger and gives the color's secondary bonus.
## Reset when the run ends. Abilities read it through PlayerAbility.power().

## Item power gained per level (0.1 = +10% per level).
@export var power_per_level: float = 0.1

@export_group("Secondary bonuses")
## Per level, as a fraction of the stat (0.05 = +5%). Adds to other % buffs on the same stat.
## Precision: perfect shot power (perfect_shot_bonus).
@export var perfect_power_per_level: float = 0.05
@export var pull_speed_per_level: float = 0.12
## Elemental: % added to every stat in DEBUFF_DURATION_STATS.
@export var debuff_per_level: float = 0.05
## Elemental: flat damage added to every stat in DEBUFF_DAMAGE_STATS. Flat, because debuff damage
## is a small whole number and a % bonus would round away.
@export var debuff_damage_per_level: float = 3.0
## Elemental: chance per level (0.04 = 4%) that any arrow hit applies Burn, Poison or Frostbite.
## Uses the normal debuff stats, so it works without elemental gear and grows with it.
@export var element_proc_per_level: float = 0.04

@export_group("Scrolls")
## Every Nth scroll (all colors counted) also gives a heart container and a full heal.
@export var scrolls_per_heart: int = 3

const HEART_GAIN_SOUND_PATH: String = "res://Audio/Player/heart_container_gain.ogg"
const HEART_GAIN_TEXT_COLOR: Color = Color(1.0, 0.35, 0.4)

const DEBUFF_DAMAGE_STATS: Array[String] = ["bleed_damage", "burn_damage", "poison_damage"]
const DEBUFF_DURATION_STATS: Array[String] = [
	"bleed_duration", "burn_duration", "poison_duration",
	"frostbite_duration", "freeze_duration", "stun_duration",
]

var scrolls_collected: int = 0
var _levels: Dictionary[CustomVariables.ItemColor, int] = {}

@onready var player: Player = get_parent() as Player

func _ready() -> void:
	EventBus.arrow_enemy_hit.connect(_on_event_bus_arrow_enemy_hit)

func get_level(color: CustomVariables.ItemColor) -> int:
	return _levels.get(color, 0)

## Multiplier for damage and effect strength of items of this color.
func get_power(color: CustomVariables.ItemColor) -> float:
	if color == CustomVariables.ItemColor.NONE:
		return 1.0
	return 1.0 + power_per_level * get_level(color)

## Multiplier for the arrow hit itself: only the equipped bow's color scales it.
func get_bow_power() -> float:
	var bow: EquipmentData = player.stats.bow
	if bow == null:
		return 1.0
	return get_power(bow.color)

## Called when the player picks a color from a scroll.
func apply_scroll(color: CustomVariables.ItemColor) -> void:
	if color == CustomVariables.ItemColor.NONE:
		return
	_levels[color] = get_level(color) + 1
	_apply_secondary(color)
	EventBus.color_level_changed.emit(color, _levels[color])
	scrolls_collected += 1
	if scrolls_per_heart > 0 and scrolls_collected % scrolls_per_heart == 0:
		player.increase_max_hp(true)
		EventBus.play_any.emit(load(HEART_GAIN_SOUND_PATH), 1.0, 1.0, -2.0)
		CombatTextSpawner.spawn(player.global_position + Vector2(0, -24), "+1 Heart", HEART_GAIN_TEXT_COLOR)

func reset() -> void:
	_levels.clear()
	scrolls_collected = 0
	for color: CustomVariables.ItemColor in CustomVariables.ItemColor.values():
		if color == CustomVariables.ItemColor.NONE:
			continue
		_apply_secondary(color)
		EventBus.color_level_changed.emit(color, 0)

## The color's secondary bonus for one level, for the scroll picker.
func bonus_text(color: CustomVariables.ItemColor) -> String:
	match color:
		CustomVariables.ItemColor.PRECISION:
			return "+%d%% perfect shot power" % roundi(perfect_power_per_level * 100.0)
		CustomVariables.ItemColor.TEMPO:
			return "+%d%% pull speed" % roundi(pull_speed_per_level * 100.0)
		CustomVariables.ItemColor.ELEMENTAL:
			return "+%d%% chance on hit to Burn, Poison or Frostbite, +%d debuff damage, +%d%% debuff duration" % [roundi(element_proc_per_level * 100.0), roundi(debuff_damage_per_level), roundi(debuff_per_level * 100.0)]
	return ""

## Equipped items of this color (the ones a scroll of it makes stronger).
func items_of_color(color: CustomVariables.ItemColor) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	for item: EquipmentData in [player.stats.bow, player.stats.arrow, player.stats.ring]:
		if item and item.color == color:
			result.append(item)
	return result

## Sets the color's stat buffs to match its current level (level 0 removes them).
func _apply_secondary(color: CustomVariables.ItemColor) -> void:
	var per_level: float = 0.0
	var stat_names: Array[String] = []
	match color:
		CustomVariables.ItemColor.PRECISION:
			per_level = perfect_power_per_level
			stat_names = ["perfect_shot_bonus"]
		CustomVariables.ItemColor.TEMPO:
			per_level = pull_speed_per_level
			stat_names = ["pull_speed"]
		CustomVariables.ItemColor.ELEMENTAL:
			per_level = debuff_per_level
			stat_names = DEBUFF_DURATION_STATS
			_set_level_buffs(DEBUFF_DAMAGE_STATS, debuff_damage_per_level, get_level(color), Stat.buff_type.ADDITIVE)
	_set_level_buffs(stat_names, per_level, get_level(color), Stat.buff_type.MULTIPLICATIVE)

func _set_level_buffs(stat_names: Array[String], per_level: float, level: int, type: Stat.buff_type) -> void:
	for stat_name: String in stat_names:
		var stat: Stat = player.stats.get(stat_name) as Stat
		if stat == null:
			push_warning("ColorLevels: '%s' is not a Stat on PlayerStats" % stat_name)
			continue
		var buff_id: int = ("color/%s" % stat_name).hash()
		stat.remove_buff_completly(buff_id, type)
		if level > 0:
			stat.add_buff(buff_id, per_level * level, type)

## Elemental scrolls: any arrow hit may apply a random elemental debuff (same debuffs and stats
## the elemental abilities use).
func _on_event_bus_arrow_enemy_hit(_perfect: bool, _arrow: Arrow, target: Enemy) -> void:
	var chance: float = element_proc_per_level * get_level(CustomVariables.ItemColor.ELEMENTAL)
	if chance <= 0.0 or not is_instance_valid(target) or target.is_dead:
		return
	if randf() >= chance:
		return
	DebuffApplier.apply(target, DebuffApplier.ELEMENTAL.pick_random())
