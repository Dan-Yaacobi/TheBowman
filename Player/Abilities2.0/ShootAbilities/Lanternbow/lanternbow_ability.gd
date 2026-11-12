class_name LanternbowAbility extends PlayerPassiveAbility
## Lanternbow: perfect shots release a wisp (up to max_wisps, each lasting wisp_lifetime). Wisps
## float beside you and fire a weak copy of every arrow you shoot. Copies carry on-hit effects but
## are never perfect shots. At the cap, a new perfect shot refreshes the oldest wisp.

@export var max_wisps: int = 3
@export var wisp_lifetime: float = 8.0
## Copy damage and knockback as a share of your shot.
@export var damage_share: float = 0.3

const COPY_TINT: Color = Color(1.0, 0.9, 0.55, 0.8)

var _host: WispHost

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(_host):
		_host = WispHost.new()
		player.add_child(_host)
	if not EventBus.arrow_released.is_connected(_on_event_bus_arrow_released):
		EventBus.arrow_released.connect(_on_event_bus_arrow_released)

func on_unequipped() -> void:
	if EventBus.arrow_released.is_connected(_on_event_bus_arrow_released):
		EventBus.arrow_released.disconnect(_on_event_bus_arrow_released)
	if is_instance_valid(_host):
		_host.queue_free()
	_host = null

func _on_event_bus_arrow_released(shot_power: float) -> void:
	if not is_instance_valid(_host):
		return
	var player: Player = PlayerManager.player
	var main_hand: PlayerMainHand = player.main_hand
	var perfect_mult: float = player.stats.perfect_shot_bonus.value() if shot_power >= 1.0 else 1.0
	for wisp: Wisp in _host.wisps():
		var copy: Arrow = main_hand.fire_at(main_hand.hand_direction, minf(shot_power, 0.99), wisp.global_position, main_hand.get_hit_abilities(), false)
		copy.regular_shot = false
		copy.damage = maxi(1, roundi(copy.damage * perfect_mult * damage_share))
		copy.knockback *= damage_share
		copy.modulate = COPY_TINT
		wisp.flash()
	# The shot that makes a wisp isn't copied by it.
	if shot_power >= 1.0:
		_host.add_wisp(max_wisps, wisp_lifetime)

func get_tooltip() -> String:
	return "Perfect shots release a wisp (up to %d, %ds) that copies your arrows for %d%% damage" % [max_wisps, roundi(wisp_lifetime), roundi(damage_share * 100.0)]

func get_tooltip_color() -> Color:
	return Color(1.0, 0.9, 0.55)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

## Keeps the wisps around the player in fixed slots.
class WispHost extends Node2D:
	const SLOTS: Array[Vector2] = [Vector2(-20, -24), Vector2(20, -24), Vector2(0, -38)]

	func wisps() -> Array[Wisp]:
		var result: Array[Wisp] = []
		for child: Node in get_children():
			if child is Wisp and not child.is_queued_for_deletion():
				result.append(child)
		return result

	func add_wisp(max_count: int, lifetime: float) -> void:
		var current: Array[Wisp] = wisps()
		if current.size() >= max_count:
			var oldest: Wisp = current[0]
			for w: Wisp in current:
				if w.time_left < oldest.time_left:
					oldest = w
			oldest.time_left = lifetime
			return
		var wisp: Wisp = Wisp.new()
		wisp.time_left = lifetime
		add_child(wisp)
		_relayout()

	func _process(_delta: float) -> void:
		_relayout()

	func _relayout() -> void:
		var current: Array[Wisp] = wisps()
		for i: int in current.size():
			current[i].home = SLOTS[i % SLOTS.size()]

## One floating light. Bobs, flashes when it fires, blinks out over its last second and a half.
class Wisp extends Node2D:
	const COLOR: Color = Color(1.0, 0.9, 0.55)
	const FADE_TIME: float = 1.5
	var time_left: float = 8.0
	var home: Vector2 = Vector2.ZERO
	var _t: float = 0.0
	var _flash: float = 0.0

	func _ready() -> void:
		z_index = 3

	func flash() -> void:
		_flash = 1.0

	func _process(delta: float) -> void:
		time_left -= delta
		if time_left <= 0.0:
			queue_free()
			return
		_t += delta
		_flash = maxf(_flash - delta * 5.0, 0.0)
		position = position.lerp(home + Vector2(0, sin(_t * 3.0) * 2.0), minf(delta * 10.0, 1.0))
		modulate.a = 1.0 if time_left > FADE_TIME else (0.35 + 0.65 * absf(sin(_t * 12.0)))
		queue_redraw()

	func _draw() -> void:
		var glow: float = 1.0 + _flash
		draw_circle(Vector2.ZERO, 6.0 * glow, Color(COLOR, 0.25))
		draw_circle(Vector2.ZERO, 3.5, Color(COLOR, 0.9))
		draw_circle(Vector2.ZERO, 1.5, Color.WHITE)
