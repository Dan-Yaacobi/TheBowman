class_name ConditionalStatBuff extends Node
## Holds a stat buff on while a condition is true (e.g. "while airborne"), checked every physics frame.
## Lives on the player; removes its buff when freed.

var stat: Stat
var buff_id: int
var amount: float
var type: Stat.buff_type = Stat.buff_type.MULTIPLICATIVE
## Returns bool. Bound to the owning ability, which outlives this node while equipped.
var condition: Callable

var _active: bool = false

func _physics_process(_delta: float) -> void:
	if stat == null or not condition.is_valid():
		return
	var should_be_active: bool = condition.call()
	if should_be_active == _active:
		return
	_active = should_be_active
	if _active:
		stat.add_buff(buff_id, amount, type)
	else:
		stat.remove_buff_completly(buff_id, type)

func _exit_tree() -> void:
	if _active and stat:
		stat.remove_buff_completly(buff_id, type)
	_active = false
