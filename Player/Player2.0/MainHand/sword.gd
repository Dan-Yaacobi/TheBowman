class_name Sword extends Node2D

@export var stats: SwordStats
@onready var slash_hurt_box: HurtBox = $SlashHurtBox

func _ready() -> void:
	set_sword()

func set_sword() -> void:
	slash_hurt_box.damage = stats.damage
	slash_hurt_box.knockback_power = stats.knockback_power
	slash_hurt_box.successful_hit.connect(sword_hit)
	
func sword_hit(_hurt_box, _hit_box) -> void:
	EventBus.sword_hit.emit(_hit_box.get_parent())
	
func set_bleed_chance(_amount: int) -> void:
	stats.bleed_chance = _amount
	
func get_bleed_chance() -> int:
	return stats.bleed_chance
	
