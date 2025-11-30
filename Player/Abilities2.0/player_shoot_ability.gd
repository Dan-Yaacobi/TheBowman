class_name PlayerShootAbility extends Resource

var activated: bool = true

func add_ability() -> void:
	pass
	
func activate_ability(_arrow: Arrow) -> void:
	pass

func update_ability() -> void:
	pass

func deactivate_ability() -> void:
	activated = false

func reactivate_ability() -> void:
	activated = true
