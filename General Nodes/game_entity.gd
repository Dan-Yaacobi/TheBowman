class_name GameEntity extends CharacterBody2D
# A General class for character entities for different interactions
# for example for applying debuff handler on both the player and the enemies without duplicating code
@onready var debuff_handler: DebuffHandler = $DebuffHandler

func take_damage(_hurt_box: HurtBox, raw_damage: int = 0) -> void:
	_handle_take_damage(_hurt_box, raw_damage)
	pass
	
func show_damage(_amount: int, color: Color) -> void:
	CombatTextSpawner.spawn(global_position, str(_amount),color)
	
func apply_debuff(_debuff: Debuff, _duration: float, _ticks: int) -> void:
	debuff_handler.add_debuff(_debuff, _duration, _ticks)

func _handle_take_damage(_hurt_box: HurtBox, raw_damage) -> void:
	pass
