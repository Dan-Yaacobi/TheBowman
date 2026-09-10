class_name ArrowHurtBox extends HurtBox

var arrow: Arrow

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	
func set_arrow(_arrow: Arrow) -> void:
	if _arrow:
		arrow = _arrow
		
func AreaEnetered( a : Area2D) -> void:
	combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
	effect_color = DEFAULT_HIT_EFFECT_COLOR
	if a is HitBox:
		damage = arrow.damage
		knockback_power = arrow.knockback
		knockback_dir = arrow.velocity.normalized()
		a.TakeDamage(self)
		arrow.hit(a)
		if a.get_parent() is Enemy:
			_apply_effects(a.get_parent())
		GeneralFunctions.hit_freeze(0.03)
		
func hit_wall(_m1,_m2,_m3,_m4) -> void:
	arrow.hit_wall(_m1,_m2,_m3,_m4)
