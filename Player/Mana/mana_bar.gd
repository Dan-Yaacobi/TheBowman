class_name ManaBar extends ProgressBar

@onready var regenrate_timer: Timer = $Regenerate

@export var mana_rate: float
@export var shoot_cost: int
@export var bar_color: Color

func _ready() -> void:
	set_value_to_max()
	regenrate_timer.timeout.connect(regenerate_mana)
	regular_color()
	
func _process(delta: float) -> void:
	if regenrate_timer.is_stopped():
		regenrate_timer.start()
	pass

func set_mana_bar_stats(_mana_rate: float, _shoot_cost: int) -> void:
	mana_rate = _mana_rate
	shoot_cost = _shoot_cost
	pass

func use_mana(_cost_multiplier) -> bool:
	if value >= shoot_cost * _cost_multiplier:
		value -= shoot_cost * _cost_multiplier
		return true
	return false

func regular_color() -> void:
	change_color(bar_color)
	
func change_color(new_color: Color) -> void:
	modulate = new_color
	
func set_value_to_max() -> void:
	value = max_value
	
func regenerate_mana() -> void:
	if value < max_value:
		value += mana_rate
	
