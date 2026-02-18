class_name Stat extends Resource

@export var base_value: float = 0.0

enum buff_type{ADDITIVE, MULTIPLICATIVE}

var additive_mod: Array[Stat_Buff] = []
var multi_mod: Array[Stat_Buff] = []

class Stat_Buff:
	var id: int
	var amount: float
	var type: buff_type
	var stacks: int = 0
	
	func _init(_id: int, _amount: float, _type: buff_type) -> void:
		id = _id
		amount = _amount
		type = _type
		increase_stack()
	func get_amount() -> float:
		return amount * stacks
	
	func increase_stack() -> void:
		stacks += 1
	
	## returns true if reducing stack by 1 was possible
	func reduce_stack() -> bool:
		if stacks > 0:
			stacks -= 1
			return true
		return false
	
	func reduce_all_stack() -> void:
		while reduce_stack():
			continue
			
func value() -> float:
	var add_sum: float = 0.0
	var mult_sum: float = 0.0
	for mod in additive_mod:
		add_sum += mod.get_amount()
	
	for mod in multi_mod:
		mult_sum += mod.get_amount()
		
	return (base_value + add_sum) * (1.0 + mult_sum)

func add_buff(id: int,amount: float, type: buff_type) -> void:
	var array: Array[Stat_Buff]
	if type == buff_type.ADDITIVE:
		array = additive_mod
	elif type == buff_type.MULTIPLICATIVE:
		array = multi_mod
	
	var found: bool = false
	for mod in array:
		if mod.id == id:
			mod.increase_stack()
			found = true
			break
	if !found:
		var new_buff: Stat_Buff = Stat_Buff.new(id,amount,type)
		array.append(new_buff)

func remove_buff_completly(id: int, type: buff_type) -> void:
	pass
	
func remove_buff_stack(id: int, type: buff_type) -> void:
	var array: Array[Stat_Buff]
	if type == buff_type.ADDITIVE:
		array = additive_mod
	elif type == buff_type.MULTIPLICATIVE:
		array = multi_mod
	
	for mod in array:
		if mod.id == id:
			mod.reduce_stack()
			array.erase(mod)
			break
	
	
