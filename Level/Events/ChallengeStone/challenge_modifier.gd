class_name ChallengeModifier extends Resource

@export var display_name: String
@export_multiline var description: String

func apply(_challenge: ChallengeStoneEvent) -> void:
	pass

func remove(_challenge: ChallengeStoneEvent) -> void:
	pass
