class_name HurtBox extends Area2D

signal successful_hit(hurt_box: HurtBox, hit_box: Area2D, _result: DamageResult)

const DEFAULT_COMBAT_TEXT_COLOR = Color.WHITE
const DEFAULT_HIT_EFFECT_COLOR = Color("ba0000")

var damage: int  = 1
var base_damage: int = 1
var damage_multiplier: float = 1.0

var knockback_power: float
var knockback_dir: Vector2
var one_time_hit: bool = false
var combat_text_color: Color
var effect_color: Color

var before_effects: Array = []
var after_effects: Array = []

var use_default_color: bool = true

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	use_default_color = true
	
func AreaEnetered(a: Area2D) -> void:
	if not a is HitBox:
		return
	if use_default_color:
		combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
	effect_color = DEFAULT_HIT_EFFECT_COLOR
	knockback_dir = (a.global_position - self.global_position).normalized()	
	if a.get_parent() is GameEntity:
		_apply_before_effects(a.get_parent())
	damage = roundi(base_damage * damage_multiplier)

	var result := DamageResult.new()
	a.TakeDamage(self,result)
	successful_hit.emit(self, a, result)
	
	if a.get_parent() is GameEntity:
		_apply_after_effects(a.get_parent(),get_parent(), result)
	

func set_text_color(_color: Color) -> void:
	use_default_color = false
	combat_text_color = _color

func add_before_effect(effect: Callable) -> void:
	before_effects.append(effect)

func add_after_effect(effect: Callable) -> void:
	after_effects.append(effect)

func _apply_after_effects(entity: GameEntity, _parent: Node2D, result: DamageResult) -> void:
	for effect in after_effects:
		if effect.is_valid():
			effect.call(entity,_parent,result)

func _apply_before_effects(entity: GameEntity) -> void:
	for effect in before_effects:
		if effect.is_valid():
			effect.call(entity)
