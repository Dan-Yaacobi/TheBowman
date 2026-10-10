class_name VampiricLeechAbility extends PlayerPassiveAbility

@export_range(0, 100, 1, "suffix:%") var heal_chance: int
@export var heal_amount: int = 1
@export var drain_shader: Shader

func on_equipped() -> void:
	EventBus.dealt_bleed_damage.connect(heal)

func on_unequipped() -> void:
	EventBus.dealt_bleed_damage.disconnect(heal)

func heal(_damage_dealt: int, _entity: GameEntity) -> void:
	if randf_range(0, 100) > heal_chance:
		return
	var player: Node2D = PlayerManager.player
	player.heal(heal_amount)
	if not is_instance_valid(_entity):
		return
	var line: BleedDrainLine = BleedDrainLine.new()
	line.setup(_entity, player, drain_shader)
	player.get_tree().current_scene.add_child(line)

func get_tooltip() -> String:
	return "Bleed damage has a %d%% chance to heal you for %d" % [heal_chance, heal_amount]
