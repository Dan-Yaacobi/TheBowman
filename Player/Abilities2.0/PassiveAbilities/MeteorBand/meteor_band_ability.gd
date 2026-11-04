class_name MeteorBandAbility extends PlayerPassiveAbility
## Hold Down in the air to fast-fall. Slamming into the ground or an enemy sends out a knockback shockwave.

@export var fall_speed_mult: float = 2.2
@export var fall_accel: float = 1600.0
## Fast-fall must last this long before a slam counts (a tap of Down does nothing).
@export var min_slam_time: float = 0.12
@export var radius: float = 56.0
@export var damage: int = 4
@export var knockback: float = 320.0
## Upward speed after slamming into an enemy.
@export var enemy_bounce: float = 200.0

const WAVE_COLOR: Color = Color(1.0, 0.6, 0.25)

var _helper: MeteorHelper

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(_helper):
		_helper = MeteorHelper.new()
		_helper.ability = self
		player.add_child(_helper)
	if not player.jump_action.landed.is_connected(_on_landed):
		player.jump_action.landed.connect(_on_landed)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.jump_action.landed.is_connected(_on_landed):
		player.jump_action.landed.disconnect(_on_landed)
	if is_instance_valid(_helper):
		_helper.stop()
		_helper.queue_free()
	_helper = null

func _on_landed() -> void:
	if is_instance_valid(_helper) and _helper.slam_ready():
		slam(PlayerManager.player.global_position + Vector2(0, 10))
	if is_instance_valid(_helper):
		_helper.stop()

func slam(center: Vector2) -> void:
	var player: Player = PlayerManager.player
	PushWave.burst(player.get_world_2d(), center, radius, knockback * power(), maxi(1, roundi(damage * power())), WAVE_COLOR)
	EventBus.camera_shake.emit(1.5, 10.0)

func get_tooltip() -> String:
	return "Hold Down in the air to slam. Landing sends out a shockwave"

func get_tooltip_color() -> Color:
	return WAVE_COLOR

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

## Lives on the player while Meteor Band is equipped: drives the fast-fall and enemy slams.
class MeteorHelper extends Node:
	var ability: MeteorBandAbility
	var slamming: bool = false
	var slam_time: float = 0.0
	var _base_max_fall: int = 0
	var _trail: CPUParticles2D

	func _ready() -> void:
		process_physics_priority = -1
		_trail = CPUParticles2D.new()
		_trail.emitting = false
		_trail.local_coords = false
		_trail.amount = 20
		_trail.lifetime = 0.3
		_trail.direction = Vector2.UP
		_trail.spread = 10.0
		_trail.gravity = Vector2.ZERO
		_trail.initial_velocity_min = 10.0
		_trail.initial_velocity_max = 25.0
		_trail.scale_amount_min = 1.5
		_trail.scale_amount_max = 3.0
		_trail.color = Color(1.0, 0.6, 0.25, 0.8)
		var parent: Node2D = get_parent() as Node2D
		if parent:
			parent.add_child.call_deferred(_trail)

	func slam_ready() -> bool:
		return slamming and slam_time >= ability.min_slam_time

	func _physics_process(delta: float) -> void:
		var player: Player = get_parent() as Player
		if player == null:
			return
		var wants: bool = not player.is_on_floor() and Input.is_action_pressed("Down") and not player.jump_action.dropping and not player.is_dash()
		if not wants:
			if slamming and not player.is_on_floor():
				stop()
			return
		if not slamming:
			slamming = true
			slam_time = 0.0
			_base_max_fall = player.stats.max_down_gravity
			player.stats.max_down_gravity = roundi(_base_max_fall * ability.fall_speed_mult)
			_trail.emitting = true
		slam_time += delta
		player.velocity.y = maxf(player.velocity.y, 0.0) + ability.fall_accel * delta
		if slam_time >= ability.min_slam_time:
			var feet: Vector2 = player.global_position + Vector2(0, 10)
			if not MinorHitHelpers.enemies_in_radius(player.get_world_2d(), feet, 12.0).is_empty():
				ability.slam(feet)
				stop()
				player.velocity.y = -ability.enemy_bounce

	func stop() -> void:
		if not slamming:
			return
		slamming = false
		var player: Player = get_parent() as Player
		if player:
			player.stats.max_down_gravity = _base_max_fall
		if is_instance_valid(_trail):
			_trail.emitting = false

	func _exit_tree() -> void:
		stop()
		if is_instance_valid(_trail):
			_trail.queue_free()
