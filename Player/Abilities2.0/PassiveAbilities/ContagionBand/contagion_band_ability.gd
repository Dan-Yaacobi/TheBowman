class_name ContagionBandAbility extends PlayerPassiveAbility
## Contagion Band: when an enemy carrying elemental debuffs (Burn, Poison, Frostbite) dies, they
## jump to the nearest enemy, shown by a short link. Strength scales with the ring's color level.

@export var jump_radius: float = 160.0
@export var link_color: Color = Color(0.55, 1.0, 0.45)

func on_equipped() -> void:
	if not EventBus.enemy_died.is_connected(_on_event_bus_enemy_died):
		EventBus.enemy_died.connect(_on_event_bus_enemy_died)

func on_unequipped() -> void:
	if EventBus.enemy_died.is_connected(_on_event_bus_enemy_died):
		EventBus.enemy_died.disconnect(_on_event_bus_enemy_died)

## Runs while the dead enemy still holds its debuffs.
func _on_event_bus_enemy_died(dead: Enemy) -> void:
	if not is_instance_valid(dead) or not dead.is_inside_tree():
		return
	var kinds: Array[DebuffApplier.Kind] = DebuffApplier.kinds_on(dead, DebuffApplier.ELEMENTAL)
	if kinds.is_empty():
		return
	var target: Enemy = _nearest_other(dead)
	if target == null:
		return
	for kind: DebuffApplier.Kind in kinds:
		DebuffApplier.apply(target, kind, power())
	var link: ContagionLink = ContagionLink.new()
	link.from = dead.global_position
	link.to = target.global_position
	link.color = link_color
	EventBus.summon_effect.emit(link)

func _nearest_other(dead: Enemy) -> Enemy:
	var best: Enemy = null
	var best_dist: float = INF
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(dead.get_world_2d(), dead.global_position, jump_radius):
		if enemy == dead or enemy.is_dead:
			continue
		var dist: float = enemy.global_position.distance_squared_to(dead.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

func get_tooltip() -> String:
	return "When an enemy with Burn, Poison or Frostbite dies, its debuffs jump to the nearest enemy"

func get_tooltip_color() -> Color:
	return Color(0.55, 1.0, 0.45)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

## A quick fading line from the dead enemy to the infected one.
class ContagionLink extends Line2D:
	const FADE_TIME: float = 0.35
	var from: Vector2
	var to: Vector2
	var color: Color = Color.GREEN
	var thickness: float = 2.0

	func _ready() -> void:
		top_level = true
		width = thickness
		default_color = color
		add_point(from)
		add_point(to)
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)
		tween.tween_callback(queue_free)
