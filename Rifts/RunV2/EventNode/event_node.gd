class_name EventNode extends RunNodeWorld
## Hosts one existing event scene as a node. The event's own exit portal leads on
## (GameManager routes event_exit_requested to the next crossroads).

## Events this node can roll, by weight and repeat penalty (see EventEntry).
@export var event_entries: Array[EventEntry] = []

@onready var loot_manager: LootManager = $LootManager

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Event test (debug hub portal): this event instead of a roll, free falls, no run state.
var _test_scene: PackedScene = null


## Called by GameManager before the node enters the tree.
func setup_test(event_scene: PackedScene) -> void:
	_test_scene = event_scene
	counts_as_node = false
	counts_as_run = false


func extra_node_set_functions() -> void:
	# Event rewards and item blessings drop through the world's loot manager.
	loot_manager.set_up()
	var scene: PackedScene = _test_scene if _test_scene else _roll_event_scene()
	if scene == null:
		push_error("EventNode: no eligible event")
		return
	current_event = scene.instantiate()
	add_child(current_event)
	if _test_scene:
		for node: Node in current_event.find_children("*", "Area2D", true, false):
			if node is FallingDeath:
				(node as FallingDeath).costs_heart = false


func extra_node_exit_functions() -> void:
	loot_manager.unset_up()


func spawn_position() -> Vector2:
	if is_instance_valid(current_event):
		return current_event.get_event_spawn()
	return super.spawn_position()


func on_world_ready() -> void:
	if is_instance_valid(current_event):
		current_event.on_event_entered()
		EventBus.event_entered.emit()


func _roll_event_scene() -> PackedScene:
	var level: int = PlayerManager.player.stats.rift_level
	var picks: Dictionary[EventEntry, int] = {}
	if route:
		picks = route.event_picks
	var eligible: Array[EventEntry] = []
	var weights: PackedFloat32Array = PackedFloat32Array()
	for entry: EventEntry in event_entries:
		if entry == null or not entry.is_eligible(level):
			continue
		var weight: float = entry.get_weight(picks.get(entry, 0))
		if weight <= 0.0:
			continue
		eligible.append(entry)
		weights.append(weight)
	if eligible.is_empty():
		return null
	var picked: EventEntry = eligible[rng.rand_weighted(weights)]
	picks[picked] = picks.get(picked, 0) + 1
	return picked.get_scene(rng)
