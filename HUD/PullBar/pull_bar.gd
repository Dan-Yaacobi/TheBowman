class_name PullBar extends TextureProgressBar

const PERFECT_THRESHOLD: float = 1.0
const OVERCHARGE_COLOR: Color = Color(0.62, 0.35, 0.95)
const OVERCHARGE_FLASH_PERIOD: float = 0.2
## The next shot is guaranteed perfect (Telegraphed shot).
const CHARGED_SHOT_COLOR: Color = Color(1.0, 0.82, 0.25)

@export var release_speed: float = 5
@export var fade_speed: float = 0.1
func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	value = 0.0
	modulate.a = 0.0

func _process(delta: float) -> void:
	var shooting: bool = PlayerManager.player.shooting
	var target_alpha: float = 1.0 if shooting else 0.0

	if shooting:
		var shot_power: float = PlayerManager.player.get_curr_shot_power()
		var overcharge: float = PlayerManager.player.get_curr_overcharge()
		if overcharge > 0.0:
			# Second fill (Longing) in its own color; flashes white once full.
			value = overcharge
			var full_flash: bool = overcharge >= 1.0 and fmod(Time.get_ticks_msec() / 1000.0, OVERCHARGE_FLASH_PERIOD) < OVERCHARGE_FLASH_PERIOD / 2.0
			tint_progress = Color.WHITE if full_flash else OVERCHARGE_COLOR
		else:
			value = shot_power
			tint_progress = CHARGED_SHOT_COLOR if PlayerManager.player.main_hand.next_shot_perfect else _color_for_power(shot_power)
	else:
		value = lerpf(value, 0.0, release_speed * delta)

	modulate.a = lerp(modulate.a, target_alpha, fade_speed)

func _color_for_power(power: float) -> Color:
	var t: float = clampf(power, 0.0, 1.0)
	var col: Color = Color.GREEN.lerp(Color.YELLOW, t / 0.5) if t < 0.5 else Color.YELLOW.lerp(Color.RED, (t - 0.5) / 0.5)
	return col
