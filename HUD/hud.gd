class_name HUD extends CanvasLayer

## Peak strength of the red edge glow when the player is hit.
const DAMAGED_GLOW_ALPHA: float = 0.55

@onready var rift_level_label: Label = $RiftLevel
@onready var damaged_flash: ColorRect = $DamagedFlash
@onready var heal_flash: ColorRect = $HealFlash
@onready var boss_health_bar: Control = $Control/BossHealthBar
@onready var boss_bar: HealthBar = $Control/BossHealthBar/HealthBar  # drag the actual node in to get the right path
@onready var item_prompt: ItemInspectPrompt = $ItemInspectPrompt
@onready var comparison_screen: ItemComparisonScreen = $ItemComparisonLayer/ItemComparisonScreen
@onready var equipment_menu: EquipmentMenu = $EquipmentMenu
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var active_ability_picker: ActiveAbilityPicker = $ActiveAbilityPicker
@onready var health_hearts: HealthHearts = $Control/HealthHearts
@onready var resource_hud: ResourceHud = $Control/ResourceHud

var current_view_item: Equipment
var flash_tween: Tween
var damage_glow_tween: Tween

func _ready() -> void:
	PlayerManager.player.item_amount_changed.connect(update_currency)
	EventBus.equipment_interaction_enter.connect(show_equip_interaction_ui)
	EventBus.equipment_interaction_exit.connect(hide_equip_interaction_ui)
	comparison_screen.equip_pressed.connect(equip_item)
	EventBus.entered_rift.connect(show_rift_label)
	rift_level_label.modulate.a = 0
	EventBus.damaged_flash.connect(apply_damage_flash)
	EventBus.healed_flash.connect(apply_heal_flash)
	damaged_flash.modulate.a = 0.0
	_setup_damaged_glow()
	heal_flash.modulate.a = 0.0
	boss_health_bar.hide()
	EventBus.boss_fight_started.connect(_on_boss_fight_started)
	EventBus.hide_boss_health_bar.connect(hide_boss_health_bar)
	pause_menu.setup(equipment_menu)
	
## The damage flash is a red vignette (edges glow, middle barely tinted), faded by modulate alpha.
func _setup_damaged_glow() -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://HUD/damaged_glow.gdshader")
	damaged_flash.material = material
	damaged_flash.show()

## Quick swell in, slower fade out.
func apply_damage_flash() -> void:
	if damage_glow_tween:
		damage_glow_tween.kill()
	damage_glow_tween = create_tween()
	damage_glow_tween.tween_property(damaged_flash, "modulate:a", DAMAGED_GLOW_ALPHA, 0.05)
	damage_glow_tween.tween_property(damaged_flash, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func apply_heal_flash() -> void:
	if flash_tween:
		flash_tween.kill()
	heal_flash.modulate = Color(0.0, 1.0, 0.0, 0.3)
	flash_tween = create_tween()
	flash_tween.tween_property(heal_flash, "modulate", Color(1, 0, 0, 0.0), 0.3)


func get_health_bar() -> HealthHearts:
	return health_hearts


func _on_boss_fight_started(boss: Boss) -> void:
	boss_bar.set_instant(boss.current_hp, boss.stats.max_hp)
	boss.health_changed.connect(boss_bar.set_current)
	boss.died.connect(_on_boss_died, CONNECT_ONE_SHOT)
	boss_health_bar.show()


func _on_boss_died(_boss: Enemy) -> void:
	boss_health_bar.hide()


func hide_boss_health_bar() -> void:
	boss_health_bar.hide()

func update_currency(amount: int, item: CustomVariables.items) -> void:
	resource_hud.update_amount(amount,item)


func show_equip_interaction_ui(equipment: Equipment) -> void:
	current_view_item = equipment
	item_prompt.show_for(equipment)
	comparison_screen.set_target(equipment)


func hide_equip_interaction_ui(_equip: Equipment) -> void:
	item_prompt.clear()
	comparison_screen.clear_target()
	current_view_item = null


func equip_item() -> void:
	if current_view_item:
		EventBus.equip_item.emit(current_view_item)


func show_rift_label() -> void:
	rift_level_label.text = "Rift Level: " + str(PlayerManager.player.stats.rift_level)
	rift_level_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(rift_level_label, "modulate:a", 0.0, 1.5).set_delay(1)
