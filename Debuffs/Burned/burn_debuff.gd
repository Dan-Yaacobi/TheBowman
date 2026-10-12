class_name BurnDebuff extends Debuff

var fire_damage: int = 1
var max_ticks: int = 1

func set_damage(_dmg: int) -> void:
	fire_damage = _dmg

func start_debuff_effect() -> void:
	max_ticks = ticks

func apply_debuff_effect() -> void:
	var fraction: float = float(ticks) / float(max_ticks)
	var dmg: int = maxi(1, ceili(fire_damage * fraction))
	entity.take_damage(null, dmg, null, Color.RED)

func merge(incoming: Debuff, incoming_ticks: int) -> void:
	ticks = incoming_ticks
	max_ticks = incoming_ticks
	fire_damage = maxi(fire_damage, (incoming as BurnDebuff).fire_damage)
