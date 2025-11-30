class_name Sword extends Node2D

@export var stats: SwordStats
@onready var slash_hurt_box: HurtBox = $"../../../SlashHurtBox"

func _ready() -> void:
	set_sword()

func set_sword() -> void:
	slash_hurt_box.damage = stats.damage
	slash_hurt_box.knockback = stats.knockback_power
	pass
