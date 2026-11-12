class_name HornetsNestAbility extends PlayerAbility
## Hornet's Nest: a perfect release becomes a burst of small, inaccurate arrows fired over a short
## time along your current aim. Each deals a share of the perfect hit with no knockback, and each
## gives a small recoil. Quiver on-hit effects only trigger once per enemy per burst.

@export var burst_count: int = 8
@export var burst_duration: float = 0.5
## Damage of each burst arrow as a share of the perfect arrow's.
@export var damage_share: float = 0.2
@export var spread_degrees: float = 12.0
## Recoil per burst arrow as a share of the bow's normal perfect recoil.
@export var recoil_share: float = 0.2

var _bursting: bool = false

## Runs on every arrow the player releases, before it flies.
func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = _activator as Arrow
	if arrow == null or not arrow.perfect_shot or not arrow.regular_shot or _bursting:
		return
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	var hit_set: Dictionary = {}
	var gates: Array[PlayerAbility] = [
		BurstGate.make(main_hand.get_hit_abilities(), TriggerType.BEFORE_HIT, hit_set),
		BurstGate.make(main_hand.get_hit_abilities(), TriggerType.AFTER_HIT, hit_set),
	]
	var burst_damage: int = maxi(1, roundi(arrow.damage * damage_share))
	# The perfect arrow itself is the first of the burst.
	_gate_arrow(arrow, gates)
	arrow.damage = burst_damage
	arrow.knockback = 0.0
	arrow.velocity = arrow.velocity.rotated(_random_spread())
	_burst(burst_damage, gates)

func _burst(burst_damage: int, gates: Array[PlayerAbility]) -> void:
	_bursting = true
	var player: Player = PlayerManager.player
	var interval: float = burst_duration / maxf(burst_count - 1, 1)
	_recoil(player)
	for i: int in burst_count - 1:
		await player.get_tree().create_timer(interval, false).timeout
		if not is_instance_valid(player) or not player.is_inside_tree() or player.is_dead():
			break
		var main_hand: PlayerMainHand = player.main_hand
		var direction: Vector2 = main_hand.hand_direction.rotated(_random_spread())
		var arrow: Arrow = main_hand.fire_at(direction, 0.99, main_hand.where_to_hold_arrow(), gates, false)
		arrow.regular_shot = false
		arrow.damage = burst_damage
		arrow.knockback = 0.0
		_recoil(player)
	_bursting = false

func _recoil(player: Player) -> void:
	var main_hand: PlayerMainHand = player.main_hand
	EventBus.apply_player_knockback.emit(-main_hand.hand_direction, main_hand.get_fire_recoil() * recoil_share)

func _random_spread() -> float:
	return deg_to_rad(randf_range(-spread_degrees, spread_degrees))

## Swaps an already-nocked arrow's on-hit effects for the burst's shared gates.
func _gate_arrow(arrow: Arrow, gates: Array[PlayerAbility]) -> void:
	arrow.hurt_box.before_effects = [arrow.hurt_box_stats]
	arrow.hurt_box.after_effects = []
	arrow.hurt_box.add_before_effect(gates[0].activate_ability)
	arrow.hurt_box.add_after_effect(gates[1].activate_ability)

func get_tooltip() -> String:
	return "Perfect shots spray %d small arrows over %.1fs" % [burst_count, burst_duration]

func get_tooltip_color() -> Color:
	return Color.GOLD

func get_type() -> TriggerType:
	return TriggerType.RELEASE

## Runs the real on-hit abilities only the first time any arrow of this burst hits an enemy.
class BurstGate extends PlayerAbility:
	var real: Array[PlayerAbility] = []
	var hit_set: Dictionary = {}
	var trigger: TriggerType = TriggerType.AFTER_HIT

	static func make(abilities: Array[PlayerAbility], _trigger: TriggerType, shared: Dictionary) -> BurstGate:
		var gate: BurstGate = BurstGate.new()
		for ability: PlayerAbility in abilities:
			if ability.get_type() == _trigger:
				gate.real.append(ability)
		gate.trigger = _trigger
		gate.hit_set = shared
		return gate

	func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
		if _target == null:
			return
		var id: int = _target.get_instance_id()
		if hit_set.has(id):
			return
		for ability: PlayerAbility in real:
			ability.activate_ability(_target, _activator, _result)
		# The after-hit pass runs last, so it closes the enemy for the rest of the burst.
		if trigger == TriggerType.AFTER_HIT:
			hit_set[id] = true

	func get_type() -> TriggerType:
		return trigger
