class_name QuestObjective extends Resource

@export var event_type: StringName

func matches(type: StringName, data: Dictionary) -> bool:
	return type == event_type
