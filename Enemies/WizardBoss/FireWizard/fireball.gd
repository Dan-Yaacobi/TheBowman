class_name FireBall extends Node2D

const BURN_DEBUFF = preload("uid://caiebherwxilx")

@export var damage: int = 2
@export var knockback: float = 250.0
@export var start_speed: float = 60.0
@export var max_speed: float = 240.0
## Seconds to reach max_speed
@export var ramp_time: float = 0.35
## Lower = snappier launch, higher = slower build-up
@export var ramp_curve: float = 0.5
@export var max_lifetime: float = 4.0
## Direction the head points in the sprite art, in degrees (0 = right)
@export var sprite_facing_deg: float = 0.0
@export var can_burn: bool = false

@onready var hurt_box: HurtBox = $HurtBox

var enemy_owned: bool = true

var after_hit_abilities: Array[PlayerAbility]
var before_hit_abilities: Array[PlayerAbility]

var direction: Vector2 = Vector2.RIGHT
var _time: float = 0.0
var _launched: bool = false
var _impacted: bool = false

func _ready() -> void:
	hurt_box.base_damage = damage
	hurt_box.knockback_power = knockback
	hurt_box.successful_hit.connect(_on_hit)
	hurt_box.collision_mask = 0
	if enemy_owned:
		hurt_box.set_collision_mask_value(1, true)
	else:
		hurt_box.set_collision_mask_value(3, true)
		hurt_box.set_collision_mask_value(4, true)
	for effect in after_hit_abilities:
		hurt_box.add_after_effect(effect.activate_ability)
	for effect in before_hit_abilities:
		hurt_box.add_before_effect(effect.activate_ability)
	if can_burn:
		hurt_box.add_after_effect(apply_burn)
		
func launch(start: Vector2, dir: Vector2) -> void:
	if not is_node_ready():
		await ready
	global_position = start
	direction = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	rotation = direction.angle() - deg_to_rad(sprite_facing_deg)
	hurt_box.knockback_dir = direction
	_time = 0.0
	_launched = true

func _physics_process(delta: float) -> void:
	if not _launched or _impacted:
		return
	_time += delta
	if _time >= max_lifetime:
		queue_free()
		return
	var t: float = clampf(_time / ramp_time, 0.0, 1.0)
	var speed: float = lerpf(start_speed, max_speed, ease(t, ramp_curve))
	global_position += direction * speed * delta

func _on_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	_impact()

# Optional: connect a GroundDetector's body_entered here to stop fireballs at islands
func _on_ground_detector_body_entered(body: Node2D) -> void:
	if body is Island:
		_impact()

func _impact() -> void:
	if _impacted:
		return
	_impacted = true
	queue_free()
	
func apply_burn(enemy: GameEntity, _hurt_box: Node2D, _result: DamageResult) -> void:
	var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
	burn_debuff.set_damage(roundi(PlayerManager.player.stats.burn_damage.value()))
	var duration = PlayerManager.player.stats.burn_duration.value()
	var ticks = PlayerManager.player.stats.burn_ticks.value()
	enemy.apply_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID,duration,ticks)
