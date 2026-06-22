class_name PlayerDeadState extends State

@onready var idle: PlayerIdleState = $"../Idle"

func _ready() -> void:
	pass

func Enter() -> void:
	player.velocity = Vector2.ZERO
	pass
	
func Exit() -> void:
	player.reset_equipment()
	if player.stats.reset_upgrades:
		player.reset_to_base_stats()
	player.stats.hp = player.stats.max_hp
	player.health_bar._set_health(player.stats.max_hp)
	EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)
	pass
	
func Process(_delta: float) -> State:
	return idle
	
func Physics(_delta: float) -> State:
	return null
	
func HandleInput(_event: InputEvent) -> State:
	return null
