class_name HuntersMarkAbility extends PlayerAbility
## Non-perfect hits add Mark stacks to an enemy. A perfect shot spends them all for burst damage.

@export var max_stacks: int = 5
## Burst damage per spent stack.
@export var damage_per_stack: int = 18

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or enemy.is_dead:
		return
	var arrow: Arrow = hurt_box.get_parent() as Arrow
	if arrow == null:
		return
	if arrow.perfect_shot:
		_burst(enemy)
	else:
		var mark: HuntersMark = HuntersMark.on(enemy)
		mark.max_stacks = max_stacks
		mark.add_stack()

func _burst(enemy: Enemy) -> void:
	var mark: HuntersMark = HuntersMark.find(enemy)
	if mark == null or mark.stacks <= 0:
		return
	var damage: int = roundi(mark.consume() * damage_per_stack * power())
	enemy.take_damage(null, damage)
	enemy.show_damage(damage, Color.ORANGE_RED)
	enemy.take_hit_effect()

func get_tooltip() -> String:
	return "Normal hits mark enemies. Perfect shots consume marks for burst damage"

func get_tooltip_color() -> Color:
	return Color.ORANGE_RED

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
