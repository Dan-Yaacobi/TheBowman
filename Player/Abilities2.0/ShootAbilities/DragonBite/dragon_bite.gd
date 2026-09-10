class_name DragonBite extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_box: HurtBox = $HurtBox

var direction: Vector2
var distance: float = 75
var damage: int
var abilities: Array[PlayerAbility]

func _ready() -> void:
	hurt_box.base_damage = damage
	for ability in abilities:
		hurt_box.add_effect(ability.activate_ability)
	visual_handler()
	
func set_damage(_dmg: int) -> void:
	damage = _dmg

func visual_handler() -> void:
	var angle: float = direction.angle()
	rotation = angle
	scale.x = -abs(scale.x)
	if cos(angle) < 0:
		scale.y = -abs(scale.y)
	else:
		scale.y = abs(scale.y)
	animation_player.play("Bite")
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", global_position + direction * distance, 0.3)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Bite":
		queue_free()
