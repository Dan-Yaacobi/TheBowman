class_name PineTree extends Enemy
## Rooted on an island. Dormant it looks like a plain pine and is hardened (1 damage per hit,
## no debuffs). Grows arms when the player comes close, throws pinecones that lead the player,
## and swipes anyone who comes right up to it. Never moves.

@export var gravity: float = 600.0

@onready var swipe_hurt_box: HurtBox = $SwipeHurtBox
@onready var _swipe_shape: CollisionShape2D = $SwipeHurtBox/CollisionShape2D
@onready var throw_point: Marker2D = $ThrowPoint

var pine_data: PineTreeData
## Seconds left before another swipe can start
var swipe_cooldown_left: float = 0.0


func extra_ready_functions() -> void:
	pine_data = stats as PineTreeData
	if pine_data == null:
		push_error("PineTree needs PineTreeData as its stats")
	animation_player = $Sprite2D/AnimationPlayer
	swipe_hurt_box.base_damage = pine_data.swipe_damage
	swipe_hurt_box.knockback_power = pine_data.swipe_knockback
	swipe_hurt_box.damage_multiplier = hurt_box.damage_multiplier
	swipe_hurt_box.add_before_effect(_aim_swipe_knockback)
	set_swipe_active(false)
	state_machine.Initialize.call_deferred(self)


## Only falls onto its island and rides it; knockback never moves it.
func _physics_process(delta: float) -> void:
	if swipe_cooldown_left > 0.0:
		swipe_cooldown_left -= delta
	velocity.x = 0.0
	velocity.y += gravity * delta
	move_and_slide()


func face_the_player() -> void:
	if PlayerManager.player:
		var left: bool = PlayerManager.player.global_position.x < global_position.x
		sprite.flip_h = left
		_swipe_shape.position.x = absf(_swipe_shape.position.x) * (-1.0 if left else 1.0)


func is_player_in_swipe_range() -> bool:
	var player: Node2D = PlayerManager.player
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	return absf(offset.x) <= pine_data.swipe_range and absf(offset.y) <= pine_data.swipe_height


func set_swipe_active(active: bool) -> void:
	swipe_hurt_box.set_deferred("monitoring", active)


## Throws a pinecone in an arc at where the player will be when it lands.
func throw_pinecone() -> void:
	var player: CharacterBody2D = PlayerManager.player
	if pine_data.pinecone_scene == null or player == null:
		return
	var cone: EnemyBullet = pine_data.pinecone_scene.instantiate()
	tag_attack(cone)
	cone.data = cone.data.duplicate()
	cone.data.damage = roundi(pine_data.pinecone_damage * stats.damage_dealt_multiplier.value())
	cone.data.knockback = pine_data.pinecone_knockback
	cone.data.move_speed = roundi(pine_data.pinecone_speed)
	cone.global_position = throw_point.global_position
	cone.target_position = _lead_target(cone.global_position, player)
	cone.was_fired = true
	_wire_hit_effects(cone.hurt_box, true)
	get_parent().add_child(cone)


## Player position plus their velocity over the flight time, refined once.
func _lead_target(from: Vector2, player: CharacterBody2D) -> Vector2:
	var target: Vector2 = player.global_position
	var speed: float = maxf(pine_data.pinecone_speed, 1.0)
	for i: int in 2:
		var flight_time: float = from.distance_to(target) / speed
		target = player.global_position + player.velocity * flight_time * pine_data.lead_amount
	return target


func _aim_swipe_knockback(_entity: GameEntity, _hurt_box: HurtBox) -> void:
	var dir: Vector2 = pine_data.swipe_launch_direction
	var side: float = signf(PlayerManager.player.global_position.x - global_position.x)
	if side == 0.0:
		side = 1.0
	swipe_hurt_box.knockback_dir = Vector2(absf(dir.x) * side, dir.y).normalized()
