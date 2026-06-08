class_name HUD extends CanvasLayer

@onready var health_bar: HealthBar = $Control/HealthBar
@onready var level_stats: Label = $Control/LevelStats
@onready var total_buffs: TotalBuffs = $Control/TotalBuffs
@onready var special_ability_cd: Sprite2D = $Control/SpecialAbilityCD
@onready var current_money: CurrentMoney = $Control/CurrentMoney
@onready var coin_animation: AnimationPlayer = $Control/Coin/CoinAnimation
@onready var rift_level_label: Label = $RiftLevel

@onready var interaction_ui: EquipmentInteractionUI = $InteractionUi

var current_view_item: Equipment

func _ready() -> void:
	interaction_ui.visible = false
	PlayerManager.player.money_changed.connect(update_money)
	coin_animation.play("Rotate")
	EventBus.equipment_interaction_enter.connect(show_equip_interaction_ui)
	EventBus.equipment_interaction_exit.connect(hide_equip_interaction_ui)
	interaction_ui.equip_new_item.connect(equip_item)
	interaction_ui.destory_new_item.connect(destory_item)
	EventBus.entered_rift.connect(show_rift_label)
	rift_level_label.modulate.a = 0
	
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
		
func show_equip_interaction_ui(equipment: Equipment) -> void:
	var screen_pos = equipment.get_viewport().get_canvas_transform() * equipment.position
	interaction_ui.global_position = screen_pos + Vector2(0,-50)
	interaction_ui.visible = true
	interaction_ui.set_items(equipment)
	current_view_item = equipment
	
func hide_equip_interaction_ui(_equip: Equipment) -> void:
	interaction_ui.visible = false
	current_view_item = null
	
func equip_item() -> void:
	if current_view_item:
		EventBus.equip_item.emit(current_view_item)
		
func destory_item() -> void:
	if current_view_item:
		EventBus.destory_view_item.emit(current_view_item)

func show_rift_label() -> void:
	rift_level_label.text = "Rift Level: " + str(PlayerManager.player.stats.rift_level)
	rift_level_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(rift_level_label, "modulate:a", 0.0, 1.5).set_delay(1)
