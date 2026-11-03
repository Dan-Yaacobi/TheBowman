class_name HummingbirdAbility extends PlayerShootAbility
## Releasing under the draw threshold fires a fan of small, weak arrows. A full draw fires one normal arrow.

## Raw draw (0-1) below which the fan fires.
@export var fan_threshold: float = 0.5
## Extra arrows on each side of the main one.
@export var arrows_per_side: int = 1
@export var fan_angle_degrees: float = 12.0
## Damage and knockback multiplier for every fan arrow, the main one included.
@export var fan_power_mult: float = 0.5
@export var fan_arrow_scale: float = 0.7

var _firing_fan: bool = false

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var fired: Arrow = _activator as Arrow
	if fired == null:
		return
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.shot_power >= fan_threshold:
		return
	_weaken(fired)
	if _firing_fan:
		return
	_firing_fan = true
	var direction: Vector2 = fired.velocity.normalized()
	for i in arrows_per_side:
		var offset: float = deg_to_rad(fan_angle_degrees) * (i + 1)
		main_hand.fire_at(direction.rotated(offset), main_hand.shot_power, fired.global_position)
		main_hand.fire_at(direction.rotated(-offset), main_hand.shot_power, fired.global_position)
	_firing_fan = false

func _weaken(fired: Arrow) -> void:
	fired.damage = maxi(1, roundi(fired.damage * fan_power_mult))
	fired.knockback *= fan_power_mult
	fired.global_scale *= fan_arrow_scale

func get_tooltip() -> String:
	return "Quick shots fire a fan of 3 small arrows"

func get_tooltip_color() -> Color:
	return Color.MEDIUM_SEA_GREEN
