class_name FrostAbility extends PlayerShootAbility

const FREEZE_DEBUFF = preload("uid://dewhg80xib8vt")
const FROST_BITE_DEBUFF = preload("uid://d56gf1x11e6x")

func on_equipped() -> void:
	EventBus.enemy_frostbitten_hit.connect(apply_freeze)

func on_unequipped() -> void:
	EventBus.enemy_frostbitten_hit.disconnect(apply_freeze)

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target:
		if _target is Enemy:
			if !_target.has_debuff(CustomVariables.FROSTBITE_DEBUFF_ID) and !_target.has_debuff(CustomVariables.FREEZE_DEBUFF_ID):
					apply_frostbite(_target)
			#else:
				#if _target.can_be_stunned():
					#apply_freeze(_target)
				#else: # if it cant freeze it applies frostbite again
					#apply_frostbite(_target)

func apply_freeze(_target: Enemy) -> void:
	if _target.can_be_stunned():
		var debuff: Debuff = FREEZE_DEBUFF.instantiate()
		_target.debuff_handler.add_debuff(debuff,CustomVariables.FREEZE_DEBUFF_ID,3,1)
		_target.end_debuff(CustomVariables.FROSTBITE_DEBUFF_ID)

func apply_frostbite(_target: Enemy) -> void:
	var debuff: Debuff = FROST_BITE_DEBUFF.instantiate()
	_target.debuff_handler.add_debuff(debuff,CustomVariables.FROSTBITE_DEBUFF_ID,5,1)

func get_tooltip() -> String:
	return "Applies Frostbite on hit, and Freezes Frostbitten Enemies"
