class_name HealthHearts extends Control

@export var heart_scene: PackedScene  # a Control with sibling children "HealthBar" and "GhostBar"

@onready var hearts_container: FlowContainer = $FlowContainer

var hearts: Array[HealthBar] = []
var max_hp: int = 0
var hp: int = 0

func init_health(_max_hp: int, _first_time: bool = true) -> void:
	if _first_time:
		max_hp = _max_hp
	else:
		max_hp = PlayerManager.player.initial_max_hp
	hp = max_hp
	_rebuild_hearts()
	_refresh_all()


func reduce_health(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	var remaining: int = amount
	for i in range(hearts.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var taken: int = mini(hearts[i].health, remaining)
		if taken > 0:
			hearts[i].reduce_health(taken)
			remaining -= taken


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	var remaining: int = amount
	for i in hearts.size():
		if remaining <= 0:
			break
		var heart_max: int = _heart_max_hp(i)
		var missing: int = heart_max - hearts[i].health
		var given: int = mini(missing, remaining)
		if given > 0:
			hearts[i].heal(given)
			remaining -= given


func gain_heart_container(_heal: bool = false) -> void:
	max_hp += CustomVariables.HP_PER_HEART
	if not _heal:
		hp = mini(hp, max_hp)
	else:
		hp = max_hp
	_rebuild_hearts()
	_refresh_all()


## Call this on a fall — permanently removes one heart container for the run.
func lose_heart_container() -> int:
	if hearts.is_empty():
		return max_hp
	max_hp = maxi(max_hp - CustomVariables.HP_PER_HEART, 0)
	hp = mini(hp, max_hp)
	_rebuild_hearts()
	_refresh_all()
	return max_hp


func _rebuild_hearts() -> void:
	for heart in hearts:
		heart.get_parent().queue_free()
	hearts.clear()
	
	var heart_count: int = ceili(float(max_hp) / CustomVariables.HP_PER_HEART)
	for i in heart_count:
		var heart_instance: Control = heart_scene.instantiate()
		hearts_container.add_child(heart_instance)
		var bar: HealthBar = heart_instance.get_node("HealthBar")
		bar.init_health(CustomVariables.HP_PER_HEART)
		hearts.append(bar)


func _refresh_all() -> void:
	var remaining: int = hp
	for i in hearts.size():
		var heart_max: int = _heart_max_hp(i)
		var heart_hp: int = clampi(remaining, 0, heart_max)
		hearts[i].max_value = heart_max
		hearts[i].health = heart_hp
		remaining -= heart_hp


func _heart_max_hp(index: int) -> int:
	var start: int = index * CustomVariables.HP_PER_HEART
	return clampi(max_hp - start, 0, CustomVariables.HP_PER_HEART)
