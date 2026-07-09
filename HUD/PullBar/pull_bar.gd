class_name PullBar extends TextureProgressBar

const PERFECT_THRESHOLD: float = 1.0

func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	value = 0.0
	modulate.a = 0.0

func _process(_delta: float) -> void:
	if not PlayerManager.player.shooting:
		value = 0
	var shot_power: float = PlayerManager.player.get_curr_shot_power()
	var target_alpha: float = 1.0
	modulate.a = lerp(modulate.a, target_alpha, 0.2)
	value = shot_power
	tint_progress = _color_for_power(shot_power)

func _color_for_power(power: float) -> Color:
	var t: float = clampf(power, 0.0, 1.0)
	var col: Color = Color.GREEN.lerp(Color.YELLOW, t / 0.5) if t < 0.5 else Color.YELLOW.lerp(Color.RED, (t - 0.5) / 0.5)
	return col
