class_name Boss2AbilityActivateState extends EnemyState

@onready var roam: Boss2RoamState = $"../Roam"

var abilities: Array[Boss2Ability]
var ability_chosen: Boss2Ability
var ability_index: int = 0

var done: bool = false

func init() -> void:
	for child in get_children():
		if child is Boss2Ability:
			abilities.append(child)
			child.boss = enemy
			child.ended.connect(finished)
	abilities.shuffle()

func Enter() -> void:
	done = false
	enemy.velocity = Vector2.ZERO
	ability_chosen = abilities[ability_index]
	ability_index += 1
	if ability_index == abilities.size() - 1:
		ability_index = 0
		abilities.shuffle()
	ability_chosen.activate_ability()

#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	if done:
		return roam
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null

func finished() -> void:
	done = true
