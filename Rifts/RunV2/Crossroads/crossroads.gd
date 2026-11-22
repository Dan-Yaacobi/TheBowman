class_name Crossroads extends RunNodeWorld
## A calm island between nodes holding 2-3 portals, rolled by GateRules from the node pool.

@export var node_portal_scene: PackedScene
@export var gate_rules: GateRules
@export var node_pool: Array[RunNodeData] = []

@onready var portal_slots: Node2D = $PortalSlots
@onready var info_label: Label = $InfoLabel

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func extra_node_set_functions() -> void:
	if route == null:
		# Scene run on its own: a throwaway route.
		route = RunRoute.new(5)
	if route.current_gate.is_empty():
		route.current_gate = gate_rules.roll_gate(route, node_pool, rng)
	_place_portals(route.current_gate)
	info_label.text = "Act %d  -  %d nodes to the boss" % [route.act_index + 1, route.nodes_left_in_act()]


## 2 portals use the side slots; 3 use all of them.
func _place_portals(gate: Array[RunNodeData]) -> void:
	var slots: Array[Marker2D] = []
	for child: Node in portal_slots.get_children():
		if child is Marker2D:
			slots.append(child)
	for i: int in mini(gate.size(), slots.size()):
		var portal: NodePortal = node_portal_scene.instantiate()
		portal.setup(gate[i])
		portal.position = slots[i].position
		portal_slots.add_child(portal)
