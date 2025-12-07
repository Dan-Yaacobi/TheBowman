class_name PlayerAbility extends Resource

var can_activate: bool = true

func add_ability() -> void:
	pass
	
func activate_ability() -> void:
	pass

func update_ability(_amount = 0) -> void:
	pass

func deactivate_ability() -> void:
	can_activate = false

func reactivate_ability() -> void:
	can_activate = true
