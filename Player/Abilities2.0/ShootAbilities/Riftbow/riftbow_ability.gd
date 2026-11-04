class_name RiftbowAbility extends PlayerAbility
## A perfect hit opens a wizard portal near the enemy. The portal flashes what it rolled, then fires it at that
## enemy: a burning fireball, a demonic fist with huge knockback, or a poison cloud. If the hit killed the enemy,
## the portal still opens and fires at where it died.

## How far from the enemy the portal opens.
@export var portal_distance: float = 45.0
## Portal hit damage, as a multiplier of the arrow's damage.
@export var damage_mult: float = 0.8
@export var fist_knockback: float = 500.0

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null:
		return
	var arrow: Arrow = hurt_box.get_parent() as Arrow
	if arrow == null or not arrow.perfect_shot:
		return
	var portal: RiftPortal = RiftPortal.new()
	portal.target = enemy
	portal.target_position = enemy.global_position
	portal.roll = RiftPortal.Roll.values().pick_random()
	portal.damage = maxi(1, roundi(hurt_box.damage * damage_mult * power()))
	portal.knockback = hurt_box.knockback_power
	portal.fist_knockback = fist_knockback * power()
	# Open above-ish the enemy, on a random side, so the shot comes in at an angle.
	var angle: float = deg_to_rad(randf_range(-150.0, -30.0))
	portal.global_position = enemy.global_position + Vector2.from_angle(angle) * portal_distance
	EventBus.summon_effect.emit(portal)

func get_tooltip() -> String:
	return "Perfect hits open a portal that fires a fireball, a demonic fist or a poison cloud"

func get_tooltip_color() -> Color:
	return Color.DARK_VIOLET

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
