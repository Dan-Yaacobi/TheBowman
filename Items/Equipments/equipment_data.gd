class_name EquipmentData extends Resource

enum slots{BOW,ARROW,RING}

class StatModifier:
	static var next_id: int = 0
	var id: int
	var stat_name: String
	var amount: float
	var stat_type: Stat.buff_type
	var display_name: String

	func _init(_amount: float, _stat_name: String, _type: Stat.buff_type) -> void:
		id = StatModifier.next_id
		StatModifier.next_id += 1
		amount = _amount
		stat_name = _stat_name
		stat_type = _type

# --- Authored identity ---
@export var display_name: String
@export var texture: Texture2D
@export var equipped_texture: Texture2D
@export var dropped_scale: float = 1.0
@export var equipped_scale: Vector2 = Vector2(1.0, 1.0)
@export var slot: slots
@export var pick_weight: float = 1.0            # how likely this item is picked from its pool, relative to others
@export var ability: PlayerAbility = null        # always set on the template — this item's one fixed main ability

# The item's defined core stats - always rolled, one modifier per entry, every
# time this item drops (values roll within each StatRollDef's range, but which
# stats appear is fixed). e.g. a bow always lists damage + pull_speed here;
# a ring can list crit_chance, and a quiver can leave stats it doesn't use out.
@export var guaranteed_stats: Array[StatRollDef] = []

# The random modifier pool - These are minor passive
# PlayerAbility effects (e.g. "on kill: -1s active cooldown"), a subset of
# which gets picked at roll time (see min/max_modifier_count below).
@export var possible_modifiers: Array[MinorAbility] = []
@export var min_modifier_count: int = 0
@export var max_modifier_count: int = 2

# --- Rolled instance data (filled in by LootManager.roll_item on a duplicate) ---
var rarity: float
var equipment_scene: PackedScene
var modifiers: Array = []                        # StatModifier list, rolled from guaranteed_stats
var bonus_abilities: Array[MinorAbility] = []    # minor abilities picked from possible_modifiers

func add_modifier(stat_name: String, amount: float, _type: Stat.buff_type) -> void:
	modifiers.append(StatModifier.new(amount, stat_name, _type))

func equip(player_stats: PlayerStats) -> void:
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.add_buff(mod.id, mod.amount, mod.stat_type)
	if ability:
		PlayerManager.player.register_ability(ability)
	for bonus in bonus_abilities:
		if bonus:
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
