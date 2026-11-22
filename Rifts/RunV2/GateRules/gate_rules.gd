class_name GateRules extends Resource
## Rolls the portals of one crossroads from a node pool, under Slay-the-Spire-like pacing rules.
## All values are first-guess placeholders.

@export_group("Size")
## Chance a gate has 3 portals instead of 2.
@export_range(0.0, 1.0) var three_portal_chance: float = 0.4

@export_group("Type Weights")
@export var combat_weight: float = 6.0
@export var elite_weight: float = 1.5
@export var event_weight: float = 2.0
@export var rest_weight: float = 1.0

@export_group("Rules")
## Chance every portal in a gate is combat. Never on the run's first gate or the pre-boss gate.
@export_range(0.0, 1.0) var forced_combat_chance: float = 0.15
## After this many events/rests in a row, the next gate is all combat.
@export var max_non_combat_streak: int = 2
@export var max_elites_per_gate: int = 1
## The run's first gate has no elites.
@export var calm_first_gate: bool = true
## The last gate before the boss always holds a rest portal.
@export var rest_before_boss: bool = true


func roll_gate(route: RunRoute, pool: Array[RunNodeData], rng: RandomNumberGenerator) -> Array[RunNodeData]:
	var by_type: Dictionary[RunNodeData.Type, Array] = _group_by_type(pool, route.get_biome())
	var count: int = 3 if rng.randf() < three_portal_chance else 2
	var is_first: bool = route.gates_rolled == 0
	var is_pre_boss: bool = route.nodes_left_in_act() == 1
	var forced_combat: bool = not is_pre_boss and by_type.has(RunNodeData.Type.COMBAT) and (
		route.non_combat_streak() >= max_non_combat_streak
		or (not is_first and rng.randf() < forced_combat_chance))

	var types: Array[RunNodeData.Type] = []
	if is_pre_boss and rest_before_boss and by_type.has(RunNodeData.Type.REST):
		types.append(RunNodeData.Type.REST)
	while types.size() < count:
		if forced_combat:
			types.append(RunNodeData.Type.COMBAT)
			continue
		var type: int = _roll_type(types, by_type, is_first, rng)
		if type < 0:
			break
		types.append(type as RunNodeData.Type)
	types.shuffle()

	var bags: Dictionary[RunNodeData.Type, Array] = {}
	var gate: Array[RunNodeData] = []
	for type: RunNodeData.Type in types:
		var bag: Array = bags.get(type, [])
		if bag.is_empty():
			bag = by_type[type].duplicate()
			bag.shuffle()
			bags[type] = bag
		gate.append(bag.pop_back())
	route.gates_rolled += 1
	return gate


func _group_by_type(pool: Array[RunNodeData], biome: int) -> Dictionary[RunNodeData.Type, Array]:
	var by_type: Dictionary[RunNodeData.Type, Array] = {}
	for node: RunNodeData in pool:
		if node == null or node.scene == null or not node.appears_in(biome):
			continue
		if not by_type.has(node.type):
			by_type[node.type] = []
		by_type[node.type].append(node)
	return by_type


## A weighted type that still fits this gate's rules; -1 if none does.
func _roll_type(taken: Array[RunNodeData.Type], by_type: Dictionary[RunNodeData.Type, Array],
		is_first: bool, rng: RandomNumberGenerator) -> int:
	var weights: Dictionary[RunNodeData.Type, float] = {
		RunNodeData.Type.COMBAT: combat_weight,
		RunNodeData.Type.ELITE: elite_weight,
		RunNodeData.Type.EVENT: event_weight,
		RunNodeData.Type.REST: rest_weight,
	}
	if (is_first and calm_first_gate) or taken.count(RunNodeData.Type.ELITE) >= max_elites_per_gate:
		weights[RunNodeData.Type.ELITE] = 0.0
	var options: Array[RunNodeData.Type] = []
	var option_weights: PackedFloat32Array = PackedFloat32Array()
	for type: RunNodeData.Type in weights:
		if weights[type] > 0.0 and by_type.has(type):
			options.append(type)
			option_weights.append(weights[type])
	if options.is_empty():
		return -1
	return options[rng.rand_weighted(option_weights)]
