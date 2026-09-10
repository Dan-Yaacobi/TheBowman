class_name HurtBox extends Area2D

signal successful_hit(hurt_box: HurtBox, hit_box: Area2D)

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

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	
func AreaEnetered(a: HitBox) -> void:
		combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
		effect_color = DEFAULT_HIT_EFFECT_COLOR
		knockback_dir = -(a.global_position - self.global_position).normalized()
		damage = roundi(base_damage * damage_multiplier)
		
		if a.get_parent() is GameEntity:
			_apply_before_effects(a.get_parent())
			
		a.TakeDamage(self)
		successful_hit.emit(self, a)
		
		if a.get_parent() is GameEntity:
			_apply_after_effects(a.get_parent())
	

func set_text_color(_color: Color) -> void:
	combat_text_color = _color

func add_before_effect(effect: Callable) -> void:
	before_effects.append(effect)

func add_after_effect(effect: Callable) -> void:
	after_effects.append(effect)

func _apply_after_effects(entity: GameEntity) -> void:
	for effect in after_effects:
		if effect.is_valid():
			effect.call(entity)

func _apply_before_effects(entity: GameEntity) -> void:
	for effect in before_effects:
		if effect.is_valid():
			effect.call(entity)
