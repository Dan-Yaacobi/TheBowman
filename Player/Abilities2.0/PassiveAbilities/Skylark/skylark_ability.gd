class_name SkylarkAbility extends PlayerPassiveAbility
## Drawing in mid-air slows your fall. A perfect shot in mid-air lifts you straight up (never
## sideways, so it can't throw you off an island). Each lift in the same airtime is weaker
## (lift_falloff); landing resets it.

## Fall speed cap while drawing in the air, as a fraction of the normal max fall speed.
@export var air_draw_fall_mult: float = 0.3
## Upward speed of the first lift (jump is 280).
@export var lift_speed: float = 160.0
## Multiplier per lift within one airtime: 1st, 2nd, 3rd... Lifts past the end do nothing.
@export var lift_falloff: Array[float] = [1.0, 0.6, 0.3]

var _helper: SkylarkHelper
## Lifts used since the player last stood on the ground.
var _lifts_this_air: int = 0

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(_helper):
		_helper = SkylarkHelper.new()
		_helper.ability = self
		player.add_child(_helper)
	if not player.main_hand.release.is_connected(_on_main_hand_release):
		player.main_hand.release.connect(_on_main_hand_release)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.main_hand.release.is_connected(_on_main_hand_release):
		player.main_hand.release.disconnect(_on_main_hand_release)
	if is_instance_valid(_helper):
		_helper.queue_free()
	_helper = null

func _on_main_hand_release() -> void:
	var player: Player = PlayerManager.player
	if player.is_on_floor() or player.main_hand.shot_power < 1.0:
		return
	if _lifts_this_air >= lift_falloff.size():
		return
	var lift: float = lift_speed * lift_falloff[_lifts_this_air] * power()
	_lifts_this_air += 1
	player.velocity.y = minf(player.velocity.y, -lift)

func on_landed() -> void:
	_lifts_this_air = 0

func get_tooltip() -> String:
	return "Drawing in mid-air slows your fall. Perfect air shots lift you upward"

func get_tooltip_color() -> Color:
	return Color.SKY_BLUE

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

## Lives on the player while Skylark is equipped. Runs before the player's physics each frame.
class SkylarkHelper extends Node:
	var ability: SkylarkAbility

	func _ready() -> void:
		process_physics_priority = -1

	func _physics_process(_delta: float) -> void:
		var player: Player = get_parent() as Player
		if player == null:
			return
		if player.is_on_floor():
			ability.on_landed()
			return
		if not player.main_hand.is_drawing():
			return
		var cap: float = player.stats.max_down_gravity * ability.air_draw_fall_mult
		player.velocity.y = minf(player.velocity.y, cap)
