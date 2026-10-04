class_name ChallengeShrine extends NPC

signal interacted
signal interaction_closed

func action(_index: int) -> void:
	match _index:
		0:
			interacted.emit()

func holds_interaction() -> bool:
	return true

func on_interaction_closed() -> void:
	interaction_closed.emit()

## Leaves Interacted: back to Idle, or to Gone once the challenge was started.
func end_interaction() -> void:
	var target: String = "Gone" if action_taken else "Idle"
	npc_state_machine.ChangeState(npc_state_machine.get_node(target) as NPCState)
