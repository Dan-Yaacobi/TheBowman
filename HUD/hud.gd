class_name HUD extends CanvasLayer

@onready var health_bar: HealthBar = $HealthBar
@onready var level_stats: Label = $LevelStats
@onready var total_buffs: TotalBuffs = $TotalBuffs
@onready var special_ability_cd: Sprite2D = $SpecialAbilityCD
@onready var current_money: CurrentMoney = $CurrentMoney
@onready var combo_counter: ComboCounter = $ComboCounter
@onready var coin_animation: AnimationPlayer = $Coin/CoinAnimation

func _ready() -> void:
	PlayerManager.player.money_changed.connect(update_money)
	PlayerManager.player.combo.connect(combo_counter.update_combo)
	coin_animation.play("Rotate")
func get_health_bar() -> HealthBar:
	return health_bar

func get_total_buffs() -> TotalBuffs:
	return total_buffs

func get_special_ability_cd() -> Sprite2D:
	return special_ability_cd

func update_money(amount) -> void:
	current_money.update_current_money(amount)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Exit"):
		EventBus.exit_ui.emit()
		
