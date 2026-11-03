class_name StormcallerAbility extends PlayerAbility
## Arrow hits plant a lightning rod on the enemy (max 3, a new one replaces the oldest).
## 1 rod: small zaps over time. 2 rods: a damaging lightning line between them.
## 3 rods: all three stunned, and the triangle between them stuns anything inside or crossing it. Then the rods are spent.

@export var zap_damage: int = 2
@export var zap_interval: float = 0.6
@export var line_damage: int = 3
@export var stun_duration: float = 1.5
@export var rod_lifetime: float = 10.0

var _network: StormNetwork

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or enemy.is_dead or not hurt_box.get_parent() is Arrow:
		return
	_get_network().add_rod(enemy)

func _get_network() -> StormNetwork:
	if not is_instance_valid(_network) or _network.is_queued_for_deletion():
		_network = StormNetwork.new()
		EventBus.summon_effect.emit(_network)
	var mult: float = power()
	_network.zap_damage = maxi(1, roundi(zap_damage * mult))
	_network.zap_interval = zap_interval
	_network.line_damage = maxi(1, roundi(line_damage * mult))
	_network.stun_duration = stun_duration * mult
	_network.rod_lifetime = rod_lifetime
	return _network

func on_unequipped() -> void:
	if is_instance_valid(_network):
		_network.queue_free()
	_network = null

func get_tooltip() -> String:
	return "Hits plant lightning rods. 2 rods link, 3 rods stun everything in their triangle"

func get_tooltip_color() -> Color:
	return Color.DEEP_SKY_BLUE

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
