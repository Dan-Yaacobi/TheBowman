class_name EquipmentData extends Resource
#
enum slots{BOW,ARROW,RING}
#
enum Rarity { COMMON, UNCOMMON, EPIC, LEGENDARY }

class StatModifier:
	static var next_id: int = 0
	var id: int
	var stat_name: String
	var amount: float
	var stat_type: Stat.buff_type

	func _init(_amount: float, _stat_name: String, _type: Stat.buff_type) -> void:
		id = StatModifier.next_id
		StatModifier.next_id += 1
		amount = _amount
		stat_name = _stat_name
		stat_type = _type

# --- Authored identity ---
@export var display_name: String
@export var name_color: Color
@export var texture: Texture2D
@export var equipped_texture: Texture2D
@export var dropped_scale: float = 1.0
@export var equipped_scale: Vector2 = Vector2(1.0, 1.0)
@export_group("Bow fit")
## Pixel in the texture where the right bow tip holds the string (left tip is mirrored). Zero = use equipped_scale and the fixed string points.
@export var string_tip: Vector2 = Vector2.ZERO
## Pixel in the texture the hand holds. The bow is placed so this point sits on the hand.
@export var grip_point: Vector2 = Vector2.ZERO
@export var string_color: Color = Color(1, 0.76, 0.66)
@export var string_width: float = 0.5
@export var string_style: StringStyle = StringStyle.PLAIN
## Softer, wider line behind the string. Fully transparent = no glow.
@export var string_glow_color: Color = Color(1, 1, 1, 0)
@export var string_glow_width: float = 2.0
@export_group("")

enum StringStyle { PLAIN, GLOW, PULSE, CRACKLE }
@export var slot: slots
## Which run color level scales this item.
@export var color: CustomVariables.ItemColor = CustomVariables.ItemColor.NONE
@export var pick_weight: float = 1.0
@export var ability: PlayerAbility
@export var tiers: Array[RarityTier]  = [RarityTier.new(), RarityTier.new(), RarityTier.new(), RarityTier.new()]
@export var equipment_scene: PackedScene
## Crafting at the blacksmith: 1 Skyshard plus this much of the slot's material
## (bow = wood, quiver = gold, ring = essence). See Crafting.get_craft_cost().
@export var craft_material_amount: int = 10


# --- Rolled instance data (filled in by LootManager.roll_item on a duplicate) ---
var rarity: float
var modifiers: Array[StatModifier] = []                      # StatModifier list, rolled from guaranteed_stats
var bonus_abilities: Array[MinorAbility] = []    # minor abilities picked from possible_modifiers
## Set the first time the comparison window opens for this item, so it joins the run tally once.
var tallied: bool = false

func add_modifier(stat_name: String, amount: float, _type: Stat.buff_type) -> void:
	modifiers.append(StatModifier.new(amount, stat_name, _type))

## Multiplier from this item's color level (color scrolls). Only scrolls of the same color raise it.
## Used for the color label; abilities and the bow hit read the same level elsewhere.
## Looked up at runtime like PlayerAbility.power(), so this resource never depends on Player or ColorLevels.
func power() -> float:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var manager: Node = tree.root.get_node_or_null("PlayerManager") if tree else null
	var player: Object = manager.get("player") if manager else null
	var levels: Object = player.get("color_levels") if player else null
	if levels == null:
		return 1.0
	return levels.call("get_power", color)

## Color name with its current level and bonus, e.g. "Precision  Lv 2 (+30%)".
func color_label() -> String:
	var text: String = CustomVariables.item_color_name(color)
	if color == CustomVariables.ItemColor.NONE:
		return text
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var manager: Node = tree.root.get_node_or_null("PlayerManager") if tree else null
	var player: Object = manager.get("player") if manager else null
	var levels: Object = player.get("color_levels") if player else null
	var level: int = levels.call("get_level", color) if levels else 0
	if level <= 0:
		return text
	return "%s  Lv %d (+%d%%)" % [text, level, roundi((power() - 1.0) * 100.0)]

## A rolled stat's value as applied. Color levels don't scale stat rolls: they scale the item's
## abilities (PlayerAbility.power) and, for bows, the arrow hit (ColorLevels.get_bow_power).
## Scaling rolls too would count the bow's color twice on Arrow Damage.
func scaled_amount(mod: StatModifier) -> float:
	return mod.amount

func equip(player_stats: PlayerStats) -> void:
	if color == CustomVariables.ItemColor.NONE:
		push_warning("EquipmentData: '%s' has no color assigned" % display_name)
	_apply_modifiers(player_stats)
	# Abilities are duplicated per rolled item, so stamping the color here is safe.
	if ability:
		ability.color = color
		PlayerManager.player.register_ability(ability)
	for bonus in bonus_abilities:
		if bonus:
			bonus.color = color
			PlayerManager.player.register_ability(bonus)

## Re-applies this item's rolled stats and power-baked abilities after its color level changed.
func refresh_power(player_stats: PlayerStats) -> void:
	_apply_modifiers(player_stats)
	if ability:
		ability.refresh_power()
	for bonus in bonus_abilities:
		if bonus:
			bonus.refresh_power()

func _apply_modifiers(player_stats: PlayerStats) -> void:
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.remove_buff_completly(mod.id, mod.stat_type)
		# Rolls are stored in display units (e.g. 20 for +20%); the Stat gets the real amount.
		stat.add_buff(mod.id, scaled_amount(mod) * PlayerStats.apply_scale(mod.stat_name), mod.stat_type)

func unequip(player_stats: PlayerStats) -> void:
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.remove_buff_completly(mod.id, mod.stat_type)
	if ability:
		PlayerManager.player.unregister_ability(ability)
	for bonus in bonus_abilities:
		if bonus:
			PlayerManager.player.unregister_ability(bonus)
