class_name RockGolem extends Enemy
## Ground enemy that sits on an island looking like a rock.
## Wakes when the player gets close or hits it.

## Stat buff id for the dormant damage reduction
const DORMANT_ARMOR_ID: int = 120
## The body sits this many texture pixels left of the frame centre.
## The sprite offset is mirrored on flip so the body doesn't jump when turning.
const BODY_OFFSET_X: float = 5.0

@export var gravity: float = 600.0

var golem_data: RockGolemData
var is_dormant: bool = true
## Set by a hit while dormant; the dormant state reads it to wake up
var was_hit_while_dormant: bool = false
## Horizontal speed the current state wants; knockback is added on top
var move_x: float = 0.0
var _flash_tween: Tween


func extra_ready_functions() -> void:
	golem_data = stats as RockGolemData
	if golem_data == null:
		push_error("RockGolem needs RockGolemData as its stats")
	animation_player = $Sprite2D/AnimationPlayer
	# Deferred so the dormant state's damage reduction is added after
	# init_damage_modifiers() builds the multiplier stat
	state_machine.Initialize.call_deferred(self)


func face_the_player() -> void:
	super()
	sprite.offset.x = -BODY_OFFSET_X if sprite.flip_h else BODY_OFFSET_X


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	_decay_knockback(delta)
	velocity.x = move_x + knockback_velocity.x
	move_and_slide()


func _decay_knockback(delta: float) -> void:
	var weight: float = 1.0 - exp(-stats.knockback_decay * 60.0 * delta)
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, weight)
	if knockback_velocity.length() <= stats.knockback_threshold:
		knockback_velocity = Vector2.ZERO


func knockback(_hurt_box: HurtBox, _hit_box, _result) -> void:
	if is_dormant or not stats.can_be_knockedback:
		return
	var resistance: float = golem_data.knockback_resistance if golem_data else 0.0
	knockback_velocity += _hurt_box.knockback_dir * _hurt_box.knockback_power * (1.0 - resistance)


func extra_hit_functions(_hurt_box: HurtBox) -> void:
	if is_dormant:
		was_hit_while_dormant = true
	_flash()


func _flash() -> void:
	if _flash_tween:
		_flash_tween.kill()
	sprite.modulate = Color(2.5, 2.5, 2.5)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


## Too heavy to flinch; hits only flash and push it.
func enter_damaged_state() -> void:
	pass


func is_debuff_immune() -> bool:
	return is_dormant or debuff_immune


func can_be_stunned() -> bool:
	return not is_dormant and not stats.stun_immune


func set_dormant(_dormant: bool) -> void:
	is_dormant = _dormant
	# A dormant rock doesn't hurt on touch
	hurt_box.set_deferred("monitoring", not _dormant)
