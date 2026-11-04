class_name SafetyNetAbility extends PlayerPassiveAbility
## Health milestone. Your first fall in each biome costs no heart.
## Gives the player one free fall on entering a new biome (FallingDeath spends it).

## Biome the free fall was last given for. -1 = none yet this run.
var _granted_biome: int = -1

func on_equipped() -> void:
	if not EventBus.world_ready.is_connected(_on_world_ready):
		EventBus.world_ready.connect(_on_world_ready)
	_on_world_ready()

func on_unequipped() -> void:
	if EventBus.world_ready.is_connected(_on_world_ready):
		EventBus.world_ready.disconnect(_on_world_ready)
	PlayerManager.player.free_falls = 0
	_granted_biome = -1

func _on_world_ready() -> void:
	var player: Player = PlayerManager.player
	var biome: int = _current_biome(player.stats.rift_level)
	if biome < 0:
		# In the hub: the next run starts fresh.
		_granted_biome = -1
		player.free_falls = 0
		return
	if biome != _granted_biome:
		_granted_biome = biome
		player.free_falls = 1

## Rifts 1..RIFTS_PER_TYPE (and their boss) are biome 0, and so on. -1 outside a run.
func _current_biome(rift_level: int) -> int:
	if rift_level <= 0:
		return -1
	@warning_ignore("integer_division")
	return (rift_level - 1) / CustomVariables.RIFTS_PER_TYPE

func get_tooltip() -> String:
	return "Your first fall in each biome costs no heart"
