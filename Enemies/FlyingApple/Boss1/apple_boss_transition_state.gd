class_name BossTransitionState extends EnemyState

@onready var roam: BossRoamState = $"../Roam"
@onready var summon_timer: Timer = $SummonTimer

@export var total_summons: int = 20

var finished_summoning: bool = false
var amount_summoned: int = 0

func init() -> void:
	summon_timer.timeout.connect(_spawn_apple)

func Enter() -> void:
	enemy.set_damage_multiplier(0.1)
	amount_summoned = 0
	enemy.velocity = Vector2.ZERO
	summon_timer.start()
	enemy.modulate.a = 0.5
	
func Exit() -> void:
	enemy.modulate.a = 1.0
	summon_timer.stop()
	enemy.set_damage_multiplier(1)

func Process(_delta: float) -> EnemyState:
	if finished_summoning:
		return roam
	return null
	
func Physics(_delta: float) -> EnemyState:
	return null

func _spawn_apple() -> void:
	var apple: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
		enemy.flying_apple_entry.get_factory(),
		enemy.flying_apple_entry.spawn_zone
	)
	if apple != null:
		enemy.get_parent().call_deferred("add_child", apple)
	amount_summoned += 1
	if amount_summoned >= total_summons:
		finished_summoning = true
