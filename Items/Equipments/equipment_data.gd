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
@export_group("")
@export var slot: slots
## Which run color level scales this item.
@export var color: CustomVariables.ItemColor = CustomVariables.ItemColor.NONE
@export var pick_weight: float = 1.0
@export var ability: PlayerAbility
@export var tiers: Array[RarityTier]  = [RarityTier.new(), RarityTier.new(), RarityTier.new(), RarityTier.new()]
@export var equipment_scene: PackedScene


# --- Rolled instance data (filled in by LootManager.roll_item on a duplicate) ---
var rarity: float
var modifiers: Array[StatModifier] = []                      # StatModifier list, rolled from guaranteed_stats
var bonus_abilities: Array[MinorAbility] = []    # minor abilities picked from possible_modifiers

func add_modifier(stat_name: String, amount: float, _type: Stat.buff_type) -> void:
	modifiers.append(StatModifier.new(amount, stat_name, _type))

func equip(player_stats: PlayerStats) -> void:
	if color == CustomVariables.ItemColor.NONE:
		push_warning("EquipmentData: '%s' has no color assigned" % display_name)
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.add_buff(mod.id, mod.amount, mod.stat_type)
	# Abilities are duplicated per rolled item, so stamping the color here is safe.
	if ability:
		ability.color = color
		PlayerManager.player.register_ability(ability)
	for bonus in bonus_abilities:
		if bonus:
			bonus.color = color
			PlayerManager.player.register_ability(bonus)

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
