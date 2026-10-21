class_name PlayerDeadState extends State

@onready var idle: PlayerIdleState = $"../Idle"
var display_death_screen: bool = true
var death_animation_done: bool = false

func init() -> void:
	player.body.animation_player.animation_finished.connect(_on_body_animation_finished)

func _ready() -> void:
	pass

func Enter() -> void:
	death_animation_done = false
	player.velocity = Vector2.ZERO
	player.reset_knockback()
	player.disable_jump()
	player.reset_hands()
	player.body.update_animation("Dead")

func Exit() -> void:
	player.enable_jump()
	player.reset_equipment()
	player.debuff_handler.reset_debuffs()
	if player.stats.reset_upgrades:
		player.reset_to_base_stats()
	MetaProgress.apply_to(player.stats)
	player.refresh_max_hp()
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
	if death_animation_done:
		return idle
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null

func _on_body_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Dead":
		death_animation_done = true
