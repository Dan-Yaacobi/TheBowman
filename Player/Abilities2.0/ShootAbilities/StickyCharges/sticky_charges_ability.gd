class_name StickyChargesAbility extends PlayerAbility
## Arrows stick in enemies and explode after a short fuse. Perfect shots make a bigger blast.

const EXPLOSION_PATH: String = "res://Player/Abilities2.0/MinorAbilities/ExplodeOnKill/Explosion.tscn"
const CHARGE_TEXTURE_PATH: String = "res://Items/Equipments/Quivers/Sprites/Arrows/StickyChargesArrow.png"

@export var fuse: float = 1.0
## Blast damage as a share of the arrow's damage.
@export var damage_share: float = 0.6
@export var perfect_blast_scale: float = 1.6

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator)
	if enemy == null or arrow == null:
		return
	var charge: StickyCharge = StickyCharge.new()
	charge.carrier = enemy
	charge.stick_offset = (arrow.global_position - enemy.global_position).limit_length(8.0)
	charge.rotation = arrow.rotation
	charge.fuse = fuse
	charge.damage = maxi(1, roundi(arrow.damage * damage_share * power()))
	charge.blast_scale = perfect_blast_scale if arrow.perfect_shot else 1.0
	charge.global_position = enemy.global_position + charge.stick_offset
	EventBus.summon_effect.emit(charge)

func get_tooltip() -> String:
	return "Arrows stick in enemies and explode after %.0fs for %d%% damage" % [fuse, roundi(damage_share * power() * 100.0)]

func get_tooltip_color() -> Color:
	return Color(1.0, 0.45, 0.25)

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

## A stuck arrow that follows its enemy, blinks faster as the fuse runs out, then explodes.
## Explodes where the enemy was if it dies first.
class StickyCharge extends Node2D:
	var carrier: Enemy
	var stick_offset: Vector2
	var fuse: float = 1.0
	var damage: int = 1
	var blast_scale: float = 1.0
	var _time: float = 0.0
	var _sprite: Sprite2D

	func _ready() -> void:
		z_index = 3
		_sprite = Sprite2D.new()
		_sprite.texture = load(CHARGE_TEXTURE_PATH)
		_sprite.scale = Vector2(0.6, 0.6)
		_sprite.offset = Vector2(-8, 0)
		add_child(_sprite)

	func _physics_process(delta: float) -> void:
		_time += delta
		if is_instance_valid(carrier) and not carrier.is_dead:
			global_position = carrier.global_position + stick_offset
		var left: float = maxf(fuse - _time, 0.0)
		var blink_speed: float = lerpf(4.0, 20.0, 1.0 - left / maxf(fuse, 0.01))
		_sprite.modulate = Color.WHITE.lerp(Color(1.8, 0.5, 0.3), 0.5 + 0.5 * sin(_time * blink_speed * TAU))
		if _time >= fuse:
			_explode()

	func _explode() -> void:
		set_physics_process(false)
		var explosion: Explosion = load(EXPLOSION_PATH).instantiate()
		explosion.set_damage(damage)
		explosion.scale = Vector2(blast_scale, blast_scale)
		explosion.global_position = global_position
		EventBus.summon_effect.emit(explosion)
		EventBus.camera_shake.emit(0.6 * blast_scale, 10.0)
		queue_free()
