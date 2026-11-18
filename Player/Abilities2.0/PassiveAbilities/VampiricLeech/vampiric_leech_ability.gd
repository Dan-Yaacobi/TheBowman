class_name VampiricLeechAbility extends PlayerPassiveAbility
## Bleed damage can heal you, and enemies that hurt you by touch (their own body or melee
## hit box, not projectiles) start bleeding.

const BLEED_DEBUFF_PATH: String = "res://Debuffs/Bleed/BleedDebuff.tscn"

@export_range(0, 100, 1, "suffix:%") var heal_chance: int
@export var heal_amount: int = 1
@export var drain_shader: Shader

func on_equipped() -> void:
	if not EventBus.dealt_bleed_damage.is_connected(heal):
		EventBus.dealt_bleed_damage.connect(heal)
	if not EventBus.player_damaged.is_connected(_on_event_bus_player_damaged):
		EventBus.player_damaged.connect(_on_event_bus_player_damaged)

func on_unequipped() -> void:
	if EventBus.dealt_bleed_damage.is_connected(heal):
		EventBus.dealt_bleed_damage.disconnect(heal)
	if EventBus.player_damaged.is_connected(_on_event_bus_player_damaged):
		EventBus.player_damaged.disconnect(_on_event_bus_player_damaged)

## Contact damage: the hurt box belongs to the enemy itself.
func _on_event_bus_player_damaged(_amount: int, source: Node) -> void:
	var enemy: Enemy = source.get_parent() as Enemy if source is HurtBox else null
	if enemy == null or enemy.is_dead or not enemy.is_inside_tree():
		return
	var stats: PlayerStats = PlayerManager.player.stats
	var bleed: BleedDebuff = load(BLEED_DEBUFF_PATH).instantiate()
	bleed.bleed_damage = maxi(1, roundi(stats.bleed_damage.value() * power()))
	enemy.debuff_handler.add_debuff(bleed, CustomVariables.BLEED_DEBUFF_ID, stats.bleed_duration.value(), stats.dot_ticks("bleed"))

func heal(_damage_dealt: int, _entity: GameEntity) -> void:
	if randf_range(0, 100) > heal_chance * power():
		return
	var player: Node2D = PlayerManager.player
	player.heal(heal_amount)
	if not is_instance_valid(_entity):
		return
	var line: BleedDrainLine = BleedDrainLine.new()
	line.setup(_entity, player, drain_shader)
	player.get_tree().current_scene.add_child(line)

func get_tooltip() -> String:
	return "Bleed damage has a %d%% chance to heal you for %d. Enemies that touch you start bleeding" % [roundi(heal_chance * power()), heal_amount]

func get_tooltip_color() -> Color:
	return Color.CRIMSON
