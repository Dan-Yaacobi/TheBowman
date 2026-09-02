class_name NPCInteractedState extends NPCState
@onready var gone: NPCGoneState = $"../Gone"
@onready var idle: NPCIdleState = $"../Idle"

func init() -> void:
	pass

func Enter() -> void:
	if npc.data.has_chat:
		npc.chat_box.open(npc)
	else:
		npc.action(0)
		state_machine.ChangeState(gone)

func Exit() -> void:
	if npc.data.has_chat:
		npc.chat_box.close()
	
func Process(_delta: float) -> NPCState:
	if not idle._player_in_range:
		if npc.action_taken:
			return gone
		return idle
	return null

func Physics(_delta: float) -> NPCState:
	return null

func HandleInput(_event: InputEvent) -> NPCState:
	if _event.is_action_pressed("Interact"):
		if npc.data.has_chat:
			if npc.chat_box.is_last_line and not npc.chat_box._is_typing:
				if npc.action_taken:
					return gone
				else:
					return idle
			else:
				npc.chat_box.advance()

	return null
