class_name ActiveAbilityIndicator extends Control

@onready var icon: TextureRect = $Icon
@onready var cooldown_bar: TextureProgressBar = $CoolDownBar
@onready var ready_label: Label = $ReadyLabel

var total_cooldown: float = 0.0

func _ready() -> void:
	visible = false
	EventBus.active_ability_equipped.connect(_on_ability_equipped)
	EventBus.active_ability_used.connect(_on_ability_used)
	EventBus.active_ability_ready.connect(_on_ability_ready)
	EventBus.active_ability_cleared.connect(_on_ability_cleared)
	
func _process(delta: float) -> void:
	if total_cooldown > 0 and cooldown_bar.value > 0:
		cooldown_bar.value -= delta
		
func _on_ability_cleared() -> void:
	visible = false
	total_cooldown = 0.0
	cooldown_bar.value = 0.0
	
func _on_ability_equipped(_ability: ActiveAbility) -> void:
	visible = true
	cooldown_bar.visible = true
	ready_label.visible = true
	if _ability.icon:
		icon.texture = _ability.icon
	cooldown_bar.max_value = _ability.cooldown
	cooldown_bar.value = 0.0
	if _ability.is_passive:
		cooldown_bar.visible = false
		ready_label.visible = false

func _on_ability_used(_cooldown: float) -> void:
	total_cooldown = _cooldown
	cooldown_bar.value = _cooldown
	ready_label.visible = false

func _on_ability_ready() -> void:
	cooldown_bar.value = 0.0
	ready_label.visible = true
