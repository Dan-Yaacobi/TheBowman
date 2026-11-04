class_name CleaveWaveAbility extends PlayerPassiveAbility
## Sword milestone. Each swing sends a crescent forward, about one sword length past the blade.

## Damage and knockback of the crescent, as a share of the sword's.
@export var damage_share: float = 0.6
## How far the crescent travels past the blade, before sword size.
@export var travel_distance: float = 34.0
## Where the crescent starts in front of the player, before sword size.
@export var start_offset: float = 22.0
## Wait so the crescent leaves with the slash, not before it.
@export var spawn_delay: float = 0.06

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not player.sword_swung.is_connected(_on_sword_swung):
		player.sword_swung.connect(_on_sword_swung)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.sword_swung.is_connected(_on_sword_swung):
		player.sword_swung.disconnect(_on_sword_swung)

func _on_sword_swung() -> void:
	PlayerManager.player.get_tree().create_timer(spawn_delay, false).timeout.connect(_spawn_wave)

func _spawn_wave() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player) or player.is_dead():
		return
	var size: float = player.get_sword_size()
	var direction: Vector2 = Vector2(player.body.facing_direction, 0.0)
	var sword: Sword = player.body.sword
	var wave: CleaveWave = CleaveWave.new()
	wave.direction = direction
	wave.travel = travel_distance * size
	wave.base_damage = maxi(1, floori(player.stats.sword_damage.value() * damage_share))
	wave.knockback_power = (sword.stats.knockback_power + player.stats.extra_sword_knockback.value()) * damage_share
	wave.scale = Vector2.ONE * size
	wave.global_position = player.global_position + Vector2(direction.x * start_offset * size, -2.0)
	EventBus.summon_effect.emit(wave)

func get_tooltip() -> String:
	return "Sword swings send out a crescent that hits for %d%% sword damage" % roundi(damage_share * 100.0)
