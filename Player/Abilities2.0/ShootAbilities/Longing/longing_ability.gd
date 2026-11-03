class_name LongingAbility extends PlayerShootAbility
## One overcharge stage: after a full draw, keep holding while a second fill (as long as the first draw) builds.
## Releasing after it fills fires an overcharged shot. Moving is slower while holding.

@export var overcharge_damage_mult: float = 1.8
@export var overcharge_knockback_mult: float = 1.6
@export var overcharge_scale_mult: float = 1.5
## Move speed while holding past a full draw.
@export var hold_move_mult: float = 0.55
const OVERCHARGE_TINT: Color = Color(0.82, 0.62, 1.0)

func on_equipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	main_hand.overcharge_enabled = true
	main_hand.overcharge_move_mult = hold_move_mult

func on_unequipped() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	main_hand.overcharge_enabled = false
	main_hand.overcharge = 0.0
	main_hand.overcharge_move_mult = 1.0

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var fired: Arrow = _activator as Arrow
	if fired == null or not PlayerManager.player.main_hand.is_overcharged():
		return
	var mult: float = power()
	fired.damage = roundi(fired.damage * overcharge_damage_mult * mult)
	fired.knockback *= overcharge_knockback_mult
	fired.global_scale *= overcharge_scale_mult
	fired.modulate = OVERCHARGE_TINT

func get_tooltip() -> String:
	return "Keep holding a full draw to overcharge your shot"

func get_tooltip_color() -> Color:
	return Color.MEDIUM_PURPLE
