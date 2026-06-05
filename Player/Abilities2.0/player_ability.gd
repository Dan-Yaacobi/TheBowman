class_name PlayerAbility extends Resource

@export var trigger_type: TriggerType = TriggerType.PASSIVE
@export var tier: Tier = Tier.COMMON
@export var rarity_weight: float = 1.0

var can_activate: bool = true

enum Tier { COMMON, UNCOMMON, RARE, LEGENDARY }
enum TriggerType { PASSIVE, SHOOT, JUMP, DASH }

func on_equipped() -> void:
	pass

func on_unequipped() -> void:
	pass
	
func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	pass

func update_ability(_amount = 0) -> void:
	pass

func deactivate_ability() -> void:
	can_activate = false

func reactivate_ability() -> void:
	can_activate = true
