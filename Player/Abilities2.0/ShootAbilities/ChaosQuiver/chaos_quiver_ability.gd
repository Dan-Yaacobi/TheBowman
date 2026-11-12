class_name ChaosQuiverAbility extends PlayerShootAbility
## Chaos Quiver: every hit has a chance to apply a random debuff (never Freeze).
## Debuff strength scales with the quiver's color level, like the other debuff quivers.

@export_range(0.0, 1.0) var proc_chance: float = 0.5

const KINDS: Array[DebuffApplier.Kind] = [
	DebuffApplier.Kind.BLEED, DebuffApplier.Kind.BURN, DebuffApplier.Kind.POISON,
	DebuffApplier.Kind.FROSTBITE, DebuffApplier.Kind.STUN, DebuffApplier.Kind.CURSE,
]

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	apply_quiver_debuff(_target)

func applies_quiver_debuff() -> bool:
	return true

func apply_quiver_debuff(_target: Node2D) -> void:
	var enemy: Enemy = _target as Enemy
	if enemy == null or randf() >= proc_chance:
		return
	DebuffApplier.apply(enemy, KINDS.pick_random(), power())

func get_tooltip() -> String:
	return "%d%% chance on hit to apply a random debuff" % roundi(proc_chance * 100.0)

func get_tooltip_color() -> Color:
	return Color.HOT_PINK

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
