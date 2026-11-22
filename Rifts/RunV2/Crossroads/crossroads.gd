class_name Crossroads extends RunNodeWorld
## A calm island between nodes holding 2-3 portals. Filled from the RunRoute it's given.

@export var node_portal_scene: PackedScene
## Placeholder until GateRules: portals are picked from this pool.
@export var node_pool: Array[RunNodeData] = []
@export_range(1, 3) var portal_count: int = 2
@export var portal_label_offset: Vector2 = Vector2(0, -40)

@onready var portal_slots: Node2D = $PortalSlots
@onready var info_label: Label = $InfoLabel

var _route: RunRoute


## Called by GameManager before the crossroads enters the tree.
func set_route(route: RunRoute) -> void:
	_route = route


func extra_node_set_functions() -> void:
	_fill_slots()
	if _route:
		info_label.text = "Act %d  -  %d nodes to the boss" % [_route.act_index + 1, _route.nodes_left_in_act()]


func _fill_slots() -> void:
	var slots: Array[Marker2D] = []
	for child: Node in portal_slots.get_children():
		if child is Marker2D:
			slots.append(child)
	var picks: Array[RunNodeData] = _pick_nodes(mini(portal_count, slots.size()))
	for i: int in picks.size():
		var portal: NodePortal = node_portal_scene.instantiate()
		portal.setup(picks[i])
		portal.position = slots[i].position
		portal_slots.add_child(portal)
		var label: Label = Label.new()
		label.text = picks[i].display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 3)
		label.size = Vector2(80, 12)
		label.position = slots[i].position + portal_label_offset - Vector2(40, 0)
		portal_slots.add_child(label)


## Samples without replacement; refills from the pool only when it runs out.
func _pick_nodes(amount: int) -> Array[RunNodeData]:
	var picks: Array[RunNodeData] = []
	var bag: Array[RunNodeData] = []
	for i: int in amount:
		if bag.is_empty():
			for node: RunNodeData in node_pool:
				if node != null:
					bag.append(node)
			if bag.is_empty():
				push_warning("Crossroads: node pool is empty")
				return picks
			bag.shuffle()
		picks.append(bag.pop_back())
	return picks
