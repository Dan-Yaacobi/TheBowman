class_name Sword extends Node2D

@export var stats: SwordStats
## Off by default: the Parry milestone turns it on. While on, swings destroy enemy projectiles.
@export var destroys_projectiles: bool = false

const PROJECTILES_LAYER: int = 8
@onready var slash_hurt_box: HurtBox = $SlashHurtBox
@onready var slash_shape: CollisionShape2D = $SlashHurtBox/CollisionShape2D
## Keyed by the body's attack animations (hand position, blade angle, in front/behind).
@onready var socket: Node2D = $SwordSocket
@onready var blade: Sprite2D = $SwordSocket/Blade

var base_blade_scale: Vector2

func _ready() -> void:
	base_blade_scale = blade.scale
	set_destroys_projectiles(destroys_projectiles)
	set_sword()
	end_attack()
	EventBus.player_died.connect(clear_effects)

func set_sword() -> void:
	slash_hurt_box.damage = stats.damage
	slash_hurt_box.knockback_power = stats.knockback_power + PlayerManager.player.stats.extra_sword_knockback.value()
	slash_hurt_box.successful_hit.connect(sword_hit)
	apply_visuals()

func apply_visuals() -> void:
	if stats.texture == null:
		return
	blade.texture = stats.texture
	blade.offset = stats.texture.get_size() / 2.0 - stats.grip_position

func set_destroys_projectiles(enabled: bool) -> void:
	destroys_projectiles = enabled
	slash_hurt_box.set_collision_mask_value(PROJECTILES_LAYER, enabled)

## Scales the blade and the hit area together. 1.0 = normal size.
func apply_size(size: float) -> void:
	blade.scale = base_blade_scale * size
	slash_hurt_box.scale = Vector2.ONE * size

## Hides the sword and turns the hit area off. Safe to call when an attack is interrupted.
func end_attack() -> void:
	socket.visible = false
	slash_shape.set_deferred("disabled", true)
	apply_size(1.0)

func clear_effects(_bool) -> void:
	slash_hurt_box.clear_effects()

func sword_hit(_hurt_box: HurtBox, _hit_box: Area2D, _result: DamageResult) -> void:
	EventBus.sword_hit.emit(_hit_box.get_parent())

func set_bleed_chance(_amount: int) -> void:
	stats.bleed_chance = _amount

func get_bleed_chance() -> int:
	return stats.bleed_chance
