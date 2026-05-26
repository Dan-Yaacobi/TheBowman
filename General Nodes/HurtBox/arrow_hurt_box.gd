class_name ArrowHurtBox extends HurtBox

var arrow: Arrow

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	body_shape_entered.connect(queue_free)

func set_arrow(_arrow: Arrow) -> void:
	if _arrow:
		arrow = _arrow
	
func AreaEnetered( a : Area2D) -> void:
	combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
	effect_color = DEFAULT_HIT_EFFECT_COLOR
	if a is HitBox and not one_time_hit:
		one_time_hit = true
		added_effects(a.get_parent())
		damage = arrow.damage
		knockback_power = arrow.knockback
		knockback_dir = arrow.velocity.normalized()
		arrow.hit(a.enemy)
		a.TakeDamage(self)
		
func hit_wall(_m1,_m2,_m3,_m4) -> void:
	arrow.hit_wall(_m1,_m2,_m3,_m4)
	
func added_effects(a: Enemy) -> void:
	pass
