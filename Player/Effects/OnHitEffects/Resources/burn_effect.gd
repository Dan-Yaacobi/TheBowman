class_name BurnEffect extends OnHitEffect

const PYROMANIAC = preload("res://Player/Buffs/FireBuffs/Pyromaniac.tscn")
@export var duration: float
@export var ticks: float

var has_pyromaniac: bool = false

func apply_effect(_target: Node2D, _arrow: Arrow) -> void:
	if _target is Enemy:
		var try_apply: int = randi_range(0,100)
		if try_apply <= chance:
			var burn_debuff = effect.instantiate()
			burn_debuff.set_damage(max((float(_arrow.damage) / 4),1))
			_target.apply_debuff(burn_debuff,duration,ticks)
			
			if has_pyromaniac:
				var pyro: Buff = PYROMANIAC.instantiate()
				pyro.add_stack()
				EventBus.add_player_buff.emit(pyro)
		
