class_name SkylarkAbility extends PlayerAbility
## Drawing in mid-air slows your fall. A perfect shot in mid-air pushes you away from your aim, like a rocket jump.

## Fall speed cap while drawing in the air, as a fraction of the normal max fall speed.
@export var air_draw_fall_mult: float = 0.3
## Push applied on a perfect air shot, opposite the aim (on top of the normal perfect-shot recoil).
@export var rocket_force: float = 260.0

var _helper: SkylarkHelper

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
	var push: Vector2 = -player.aim_direction.normalized()
	if push.y < 0.0:
		player.velocity.y = minf(player.velocity.y, 0.0)
	player.apply_knockback(push, rocket_force * power())

func get_tooltip() -> String:
	return "Drawing in mid-air slows your fall. Perfect air shots launch you away from your aim"

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
		if player == null or player.is_on_floor() or not player.main_hand.is_drawing():
			return
		var cap: float = player.stats.max_down_gravity * ability.air_draw_fall_mult
		player.velocity.y = minf(player.velocity.y, cap)
