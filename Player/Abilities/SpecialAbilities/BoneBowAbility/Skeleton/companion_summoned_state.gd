class_name CompanionSummonedState extends CompanionState

# store a refernece to the player this belongs to
@onready var moving: CompanionMovingState = $"../Moving"

var finished_summon: bool = false
func init() -> void:
	pass
	
func _ready() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	companion.update_animation("Summon")
	finished_summon = false
	companion.animation_player.animation_finished.connect(summoned)
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> CompanionState:
	if finished_summon:
		return moving
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> CompanionState:
	return null
	
#what happens during input events in this state
func HandleInput(_event: InputEvent) -> CompanionState:
	return null

func summoned(_v) -> void:
	finished_summon = true
	
