class_name PlayerAbility extends Resource

@export var trigger_type: TriggerType = TriggerType.PASSIVE
@export var tier: Tier = Tier.COMMON
@export var rarity_weight: float = 1.0

var can_activate: bool = true
var dynamic_debuff_id: int
## Color of the item this ability came from, stamped by EquipmentData.equip().
## NONE for abilities that don't come from an item (they don't scale).
var color: CustomVariables.ItemColor = CustomVariables.ItemColor.NONE

enum Tier { COMMON, UNCOMMON, RARE, LEGENDARY }
enum TriggerType { PASSIVE, SHOOT, JUMP, DASH, RELEASE, DRAW, AFTER_HIT, BEFORE_HIT}

func set_up() -> void:
	pass

## Multiplier for this ability's damage and effect strength, from its item's color level.
## Looked up at runtime on purpose: this base class must not depend on Player, ColorLevels
## or EventBus, or MetaProgress (which preloads abilities through its tracks) stops compiling.
func power() -> float:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var manager: Node = tree.root.get_node_or_null("PlayerManager") if tree else null
	var player: Object = manager.get("player") if manager else null
	var levels: Object = player.get("color_levels") if player else null
	if levels == null:
		return 1.0
	return levels.call("get_power", color)

func on_equipped() -> void:
	pass

func on_unequipped() -> void:
	pass
	
func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	pass

func update_ability(_amount = 0) -> void:
	pass

func deactivate_ability() -> void:
	can_activate = false

func reactivate_ability() -> void:
	can_activate = true

func get_tooltip() -> String:
	return ""

func get_tooltip_color() -> Color:
	return Color.WHITE
	
func get_type() -> TriggerType:
	return trigger_type
