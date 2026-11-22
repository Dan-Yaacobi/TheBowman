class_name RunRoute extends RefCounted
## Progress through one Run Structure v2 run: acts (one per biome), each a chain of nodes the
## player picks at crossroads, ending in the biome's wizard. Owned by GameManager for one run.

var nodes_per_act: int = 5
## 0 = dirt, 1 = snow, 2 = hell. Reaching BIOME_COUNT means every act is done.
var act_index: int = 0
## Nodes finished in the current act.
var nodes_done_in_act: int = 0
## The node being played; null while at a crossroads or in a boss arena.
var current_node: RunNodeData = null
## Every node entered this run, in order.
var history: Array[RunNodeData] = []
## The portals of the crossroads being visited. Rolled once per visit, so a reload shows the same gate.
var current_gate: Array[RunNodeData] = []
## Gates rolled this run.
var gates_rolled: int = 0
## Times each event was picked this run (event repeat penalty).
var event_picks: Dictionary[EventEntry, int] = {}


func _init(_nodes_per_act: int) -> void:
	nodes_per_act = maxi(_nodes_per_act, 1)


func enter_node(node: RunNodeData) -> void:
	current_node = node
	history.append(node)
	current_gate.clear()


func complete_node() -> void:
	current_node = null
	nodes_done_in_act += 1


func is_act_finished() -> bool:
	return nodes_done_in_act >= nodes_per_act


func nodes_left_in_act() -> int:
	return maxi(nodes_per_act - nodes_done_in_act, 0)


## The wizard died: next biome, fresh act.
func finish_act() -> void:
	act_index += 1
	nodes_done_in_act = 0
	current_node = null
	current_gate.clear()


func is_run_finished() -> bool:
	return act_index >= CustomVariables.BIOME_COUNT


func get_biome() -> Rift.Type:
	return clampi(act_index, 0, Rift.Type.size() - 1) as Rift.Type


## Non-combat nodes (events, rests) taken in a row, most recent first.
func non_combat_streak() -> int:
	var streak: int = 0
	for i: int in range(history.size() - 1, -1, -1):
		var type: RunNodeData.Type = history[i].type
		if type == RunNodeData.Type.COMBAT or type == RunNodeData.Type.ELITE:
			break
		streak += 1
	return streak


## The procedural-rift rift_level matching the next (or current) node, so systems that read
## stats.rift_level (loot, enemy entries, events, island looks, portal looks) keep working.
## The act's nodes spread evenly over the biome's RIFTS_PER_TYPE levels.
func get_equivalent_rift_level() -> int:
	var per_biome: int = CustomVariables.RIFTS_PER_TYPE
	var node_index: int = mini(nodes_done_in_act, nodes_per_act - 1)
	@warning_ignore("integer_division")
	var step: int = mini(node_index * per_biome / nodes_per_act, per_biome - 1)
	return mini(act_index, CustomVariables.BIOME_COUNT - 1) * per_biome + 1 + step
