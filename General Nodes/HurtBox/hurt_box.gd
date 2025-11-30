class_name HurtBox extends Area2D

signal successful_hit

const DEFAULT_COMBAT_TEXT_COLOR = Color.WHITE
const DEFAULT_HIT_EFFECT_COLOR = Color("ba0000")

@export var damage: int  = 1
@export var knockback: int
@export var knockback_dir: Vector2

var one_time_hit: bool = false
var combat_text_color: Color
var effect_color: Color

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	
func AreaEnetered( a : Area2D) -> void:
	if a is HitBox:
		combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
		effect_color = DEFAULT_HIT_EFFECT_COLOR
		CombatTextSpawner.spawn(a.global_position, str(damage),combat_text_color)
		knockback_dir = (a.global_position - self.global_position).normalized()
		a.TakeDamage(self)
		successful_hit.emit()
		
func added_effects(a: Enemy) -> void:
	pass
