class_name HurtBox extends Area2D

const DEFAULT_COMBAT_TEXT_COLOR = Color.WHITE
const DEFAULT_HIT_EFFECT_COLOR = Color("ba0000")

@export var damage: int  = 1

var one_time_hit: bool = false
var combat_text_color: Color
var effect_color: Color

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	
func AreaEnetered( a : Area2D) -> void:
	combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
	effect_color = DEFAULT_HIT_EFFECT_COLOR
	if a is HitBox and not one_time_hit:
		added_effects(a.get_parent())
		var parent = get_parent()
		if parent is Arrow:
			damage = parent.damage
			parent.hit(a.enemy)
			one_time_hit = true
			#parent.arrow_hit_resolve(a.get_enemy())
			#EventBus.shot_power.emit(parent.shot_power_mod)
		CombatTextSpawner.spawn(a.global_position, str(damage),combat_text_color)
		a.TakeDamage(self)

func added_effects(a: Enemy) -> void:
	pass
