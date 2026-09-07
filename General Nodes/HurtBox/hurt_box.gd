class_name HurtBox extends Area2D

signal successful_hit(hurt_box: HurtBox)

const DEFAULT_COMBAT_TEXT_COLOR = Color.WHITE
const DEFAULT_HIT_EFFECT_COLOR = Color("ba0000")

var damage: int  = 1

var knockback_power: float
var knockback_dir: Vector2
var one_time_hit: bool = false
var combat_text_color: Color
var effect_color: Color
var added_effects: Array = []

func _ready() -> void:
	area_entered.connect(AreaEnetered)
	
func AreaEnetered(a: Area2D) -> void:
	if a is HitBox:
		combat_text_color = DEFAULT_COMBAT_TEXT_COLOR
		effect_color = DEFAULT_HIT_EFFECT_COLOR
		knockback_dir = -(a.global_position - self.global_position).normalized()
		a.TakeDamage(self)
	if a.get_parent() is GameEntity:
		_apply_effects(a.get_parent())
	successful_hit.emit(self)

func set_text_color(_color: Color) -> void:
	combat_text_color = _color

func add_effect(effect: Callable) -> void:
	added_effects.append(effect)

func _apply_effects(entity: GameEntity) -> void:
	for effect in added_effects:
		if effect.is_valid():
			effect.call(entity)
