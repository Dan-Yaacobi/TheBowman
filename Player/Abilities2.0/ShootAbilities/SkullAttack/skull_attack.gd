class_name SkullAttack extends Node2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var area: Area2D = $Area2D

@export var duration: float = 5.0

const WEAKNESS_DEBUFF = preload("uid://p65b1l6p0pp1")

func _ready() -> void:
	animation_player.play("Attack")
	area.monitoring = true
	animation_player.animation_finished.connect(end)

func end(_animation: String) -> void:
	queue_free()

func _on_area_2d_area_entered(_area: Area2D) -> void:
	var entity = _area.get_parent()
	if entity is Enemy:
		var debuff: WeaknessDebuff = WEAKNESS_DEBUFF.instantiate()
		entity.apply_debuff(debuff,duration,1)
