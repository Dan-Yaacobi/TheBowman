class_name JanusAbility extends PlayerPassiveAbility
## Janus: every shot also fires a mirrored arrow straight behind you for a share of the damage.
## The mirror carries your on-hit effects but is never a perfect shot (no perfect-only procs).

## Mirror damage and knockback as a share of the shot.
@export var damage_share: float = 0.5
const MIRROR_TINT: Color = Color(0.85, 0.8, 1.0, 0.8)

func on_equipped() -> void:
	if not EventBus.arrow_released.is_connected(_on_event_bus_arrow_released):
		EventBus.arrow_released.connect(_on_event_bus_arrow_released)

func on_unequipped() -> void:
	if EventBus.arrow_released.is_connected(_on_event_bus_arrow_released):
		EventBus.arrow_released.disconnect(_on_event_bus_arrow_released)

func _on_event_bus_arrow_released(shot_power: float) -> void:
	var player: Player = PlayerManager.player
	if player == null or not player.is_inside_tree():
		return
	var main_hand: PlayerMainHand = player.main_hand
	var behind: Vector2 = -main_hand.hand_direction.normalized()
	var mirror: Arrow = main_hand.fire_at(behind, minf(shot_power, 0.99), main_hand.where_to_hold_arrow(), main_hand.get_hit_abilities(), false)
	mirror.regular_shot = false
	var perfect_mult: float = player.stats.perfect_shot_bonus.value() if shot_power >= 1.0 else 1.0
	mirror.damage = maxi(1, roundi(mirror.damage * perfect_mult * damage_share))
	mirror.knockback *= damage_share
	mirror.modulate = MIRROR_TINT

func get_tooltip() -> String:
	return "Every shot also fires a mirrored arrow behind you for %d%% damage" % roundi(damage_share * 100.0)

func get_tooltip_color() -> Color:
	return Color(0.85, 0.8, 1.0)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE
