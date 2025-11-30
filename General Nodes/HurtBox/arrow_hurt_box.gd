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
	if a is HitBox and not one_time_hit:
		one_time_hit = true
		added_effects(a.get_parent())
		damage = arrow.damage
		knockback = arrow.data.pushback_power
		knockback_dir = arrow.velocity.normalized()
		arrow.hit(a.enemy)
		#parent.arrow_hit_resolve(a.get_enemy())
		#EventBus.shot_power.emit(parent.shot_power_mod)
		CombatTextSpawner.spawn(a.global_position, str(damage),combat_text_color)
		a.TakeDamage(self)

func added_effects(a: Enemy) -> void:
	pass
