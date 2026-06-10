class_name LootManager extends Node2D
const EQUIPMENT: String = "res://Items/Equipments/Equipment.tscn"
const COIN: String = "res://Items/Other/Coin/coin.tscn"

# Rarity
@export var quality_floor_max: float = 0.8       # how high the floor gets at max rarity
@export var quality_ceiling_min: float = 0.4     # ceiling for rarity 1 items
@export var rarity_bias: float = 3.0         # higher = legendary items rarer (C base)
@export var lift_exp: float = 0.7

# Rift level scaling
@export var rift_stat_scale: float = 0.1         # A: how much stat ranges grow per rift (logarithmic)
@export var rift_quality_scale: float = 0.1      # B: how much rift level boosts quality floor
@export var rift_rarity_scale: float = 0.1       # C: how much rift level reduces rarity bias

@export var bow_pool: ItemPool
@export var quiver_pool: ItemPool
@export var ring_pool: ItemPool

@export var uncommon_ability_chance: float = 0.2
@export var rare_ability_chance: float = 0.65

enum Slot { BOW, QUIVER, RING }

func _ready() -> void:
	set_up()

func set_up() -> void:
	EventBus.try_drop.connect(drop_random_item)
	EventBus.drop_coins.connect(drop_coins)
	EventBus.drop_potion.connect(drop_potion)
	
func drop_item(slot: Slot) -> EquipmentData:
	match slot:
		Slot.BOW: return roll_item(bow_pool)
		Slot.QUIVER: return roll_item(quiver_pool)
		Slot.RING: return roll_item(ring_pool)
	return null

func drop_random_item(_position: Vector2, _chance: float) -> void:
	if randf_range(0,100) <= _chance:
		var item: EquipmentData = drop_item(randi_range(0, 1) as Slot)
		EventBus.equipment_dropped.emit(item, _position, null)

func drop_coins(_position: Vector2, _amount: int) -> void:
	ItemDropManager.drop_coins(_position, _amount)

func drop_potion(_position: Vector2, _chance: float) -> void:
	ItemDropManager.drop_potion(_position, _chance)
	
func roll_item(pool: ItemPool) -> EquipmentData:
	var data = EquipmentData.new()
	data.slot = pool.slot
	data.display_name = pool.possible_display_names.pick_random()
	data.equipment_scene = load(EQUIPMENT)
	data.dropped_scale = pool.scale
	
	var rift_level: int = PlayerManager.player.stats.rift_level

	# A: logarithmic stat range scalar — gradual growth with rift level
	var rift_stat_scalar = 1.0 + log(max(rift_level, 1)) * rift_stat_scale

	# B: rift quality floor boost — later rifts guarantee better rolls
	var rift_quality_boost = log(max(rift_level, 1)) * rift_quality_scale

	# C: rift rarity bias reduction — higher rarity items more common in later rifts
	var effective_rarity_bias = max(rarity_bias - log(max(rift_level, 1)) * rift_rarity_scale, 0.5)

	# roll rarity first
	var rarity_roll = randf()
	var rarity_curved = pow(pow(rarity_roll, lift_exp), effective_rarity_bias)
	data.rarity = 1.0 + rarity_curved * (CustomVariables.MAX_RARITY - 1)

	# stat count scales with rarity
	var rarity_normalized = (data.rarity - 1.0) / (CustomVariables.MAX_RARITY - 1.0)
	var count = pool.min_stat_count + roundi(rarity_normalized * (pool.max_stat_count - pool.min_stat_count))

	# floor and ceiling — rarity driven + rift quality boost
	var quality_floor = clampf(rarity_normalized * quality_floor_max + rift_quality_boost, 0.0, 1.0)
	var quality_ceiling = clampf(rarity_normalized * (1.0 - quality_ceiling_min) + quality_ceiling_min + rift_quality_boost, 0.0, 1.0)

	var selected = _weighted_pick(pool.possible_stats.duplicate(), count)
	for def in selected:
		var roll_normalized = randf()
		var roll_curved = pow(roll_normalized, def.rarity_weight)
		var roll_bounded = quality_floor + roll_curved * (quality_ceiling - quality_floor)
		# A: scale the actual stat range by rift scalar
		var scaled_min = def.min_value * rift_stat_scalar
		var scaled_max = def.max_value * rift_stat_scalar
		var amount = scaled_min + roll_bounded * (scaled_max - scaled_min)
		amount = snappedf(amount, 0.1)
		data.add_modifier(def.stat_name, amount, def.type)
		
	data.ability = _roll_ability(pool, roundi(data.rarity))
	
	data.texture = pool.possible_textures[mini(roundi(data.rarity) - 1, pool.possible_textures.size() - 1)]
	data.equipped_texture = pool.equipped_textures[mini(roundi(data.rarity) - 1, pool.possible_textures.size() - 1)]
	return data

func _weighted_pick(stats: Array[StatRollDef], count: int) -> Array[StatRollDef]:
	var result: Array[StatRollDef] = []
	var remaining = stats.duplicate()
	for i in count:
		if remaining.is_empty():
			break
		var total_weight = 0.0
		for stat in remaining:
			total_weight += 1.0 / stat.rarity_weight
		var roll = randf() * total_weight
		var cumulative = 0.0
		for stat in remaining:
			cumulative += 1.0 / stat.rarity_weight
			if roll <= cumulative:
				result.append(stat)
				remaining.erase(stat)
				break
	return result

func _roll_ability(pool: ItemPool, rarity: int) -> PlayerAbility:
	var chance := _ability_chance_for_rarity(rarity)
	if randf() > chance:
		return null
	
	var eligible := pool.possible_abilities.filter(
		func(a): return a.tier <= _max_ability_tier_for_rarity(rarity))
	if eligible.is_empty():
		return null
	
	return _weighted_ability_pick(eligible)

func _ability_chance_for_rarity(rarity: int) -> float:
	var t = float(rarity - 1) / float(CustomVariables.MAX_RARITY - 1)  # 0.0 at common, 1.0 at max
	if t < 0.25: return 0.0
	if t >= 1.0: return 1.0
	return lerpf(uncommon_ability_chance, rare_ability_chance, (t - 0.25) / 0.75)

func _max_ability_tier_for_rarity(rarity: int) -> PlayerAbility.Tier:
	var t = float(rarity - 1) / float(CustomVariables.MAX_RARITY - 1)
	if t < 0.25: return PlayerAbility.Tier.COMMON
	if t < 0.75: return PlayerAbility.Tier.UNCOMMON
	return PlayerAbility.Tier.LEGENDARY
		
func _weighted_ability_pick(abilities: Array) -> PlayerAbility:
	var total_weight := 0.0
	for ability in abilities:
		total_weight += 1.0 / ability.rarity_weight
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	for ability in abilities:
		cumulative += 1.0 / ability.rarity_weight
		if roll <= cumulative:
			return ability.duplicate()
	
	return abilities.back().duplicate()
