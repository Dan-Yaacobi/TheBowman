class_name NPCIdleState extends NPCState

var _player_in_range: bool = false
@onready var interacted: NPCInteractedState = $"../Interacted"

func init() -> void:
	npc.interaction_area.body_entered.connect(_on_body_entered)
	npc.interaction_area.body_exited.connect(_on_body_exited)
	pass

func Enter() -> void:
	_player_in_range = npc.interaction_area.has_overlapping_bodies()

func Exit() -> void:
	pass

func Process(_delta: float) -> NPCState:
	return null

func Physics(_delta: float) -> NPCState:
	return null

func HandleInput(_event: InputEvent) -> NPCState:
	if _event.is_action_pressed("Interact"):
		if _player_in_range:
			return interacted
	return null

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
