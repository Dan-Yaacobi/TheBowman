class_name EchoArrowsAbility extends PlayerAbility
## A perfect shot is repeated by a faint ghost arrow a moment later, from where you released it.
## The ghost carries your on-hit effects and deals a share of the perfect arrow's damage.

@export var delay: float = 0.4
## Ghost damage and knockback as a share of the perfect arrow's.
@export var damage_share: float = 0.5

const GHOST_TINT: Color = Color(0.65, 0.85, 1.0, 0.55)

var _equipped: bool = false

func on_equipped() -> void:
	_equipped = true
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if not main_hand.release.is_connected(_on_release):
		main_hand.release.connect(_on_release)

func on_unequipped() -> void:
	_equipped = false
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.release.is_connected(_on_release):
		main_hand.release.disconnect(_on_release)

func _on_release() -> void:
	var main_hand: PlayerMainHand = PlayerManager.player.main_hand
	if main_hand.shot_power < 1.0:
		return
	var origin: Vector2 = main_hand.where_to_hold_arrow()
	var direction: Vector2 = main_hand.hand_direction
	main_hand.get_tree().create_timer(delay, false).timeout.connect(_fire_ghost.bind(origin, direction))

func _fire_ghost(origin: Vector2, direction: Vector2) -> void:
	var player: Player = PlayerManager.player
	if not _equipped or player == null or not player.is_inside_tree() or player.is_dead():
		return
	var main_hand: PlayerMainHand = player.main_hand
	var ghost: Arrow = main_hand.fire_at(direction, 1.0, origin, main_hand.get_hit_abilities(), false)
	ghost.regular_shot = false
	ghost.damage = maxi(1, roundi(ghost.damage * damage_share * power()))
	ghost.knockback *= damage_share
	ghost.modulate = GHOST_TINT

func get_tooltip() -> String:
	return "Perfect shots are echoed by a ghost arrow for %d%% damage" % roundi(damage_share * power() * 100.0)

func get_tooltip_color() -> Color:
	return Color(0.65, 0.85, 1.0)

func get_type() -> TriggerType:
	return TriggerType.PASSIVE
