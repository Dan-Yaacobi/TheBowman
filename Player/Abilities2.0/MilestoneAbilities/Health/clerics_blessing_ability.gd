class_name ClericsBlessingAbility extends PlayerPassiveAbility
## Health milestone. You heal when you leave a rift through its exit portal.

## In HP (one heart = CustomVariables.HP_PER_HEART).
@export var heal_amount: int = 1

func on_equipped() -> void:
	if not EventBus.entered_rift_portal.is_connected(_on_rift_exited):
		EventBus.entered_rift_portal.connect(_on_rift_exited)

func on_unequipped() -> void:
	if EventBus.entered_rift_portal.is_connected(_on_rift_exited):
		EventBus.entered_rift_portal.disconnect(_on_rift_exited)

func _on_rift_exited() -> void:
	var player: Player = PlayerManager.player
	if is_instance_valid(player) and not player.is_dead():
		player.heal(heal_amount)

func get_tooltip() -> String:
	return "Heal %d when you exit a rift" % heal_amount
