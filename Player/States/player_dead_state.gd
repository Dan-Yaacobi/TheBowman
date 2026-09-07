class_name PlayerDeadState extends State

@onready var idle: PlayerIdleState = $"../Idle"
var display_death_screen: bool = true

func _ready() -> void:
	pass

func Enter() -> void:
	player.velocity = Vector2.ZERO

func Exit() -> void:
	player.reset_equipment()
	player.debuff_handler.reset_debuffs()
	if player.stats.reset_upgrades:
		player.reset_to_base_stats()
	player.stats.hp = player.stats.max_hp
	player.health_bar._set_health(player.stats.max_hp)
	EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)
	EventBus.player_died.emit(display_death_screen)
	reset_active_ability()
	
func reset_active_ability() -> void:
	var ability: ActiveAbility = PlayerManager.player.stats.active_ability
	if ability:
		ability.on_unequipped(PlayerManager.player)
		PlayerManager.player.stats.active_ability = null
		EventBus.active_ability_cleared.emit()
		PlayerManager.player.active_ability_available = true
		PlayerManager.player.active_ability_cooldown.stop()
	
func Process(_delta: float) -> State:
	return idle
	
func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null
