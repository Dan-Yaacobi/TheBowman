class_name RiftPortal extends Node2D
## Opens near an enemy from four rune stones, painted in the colour of what it rolled. It swirls and pulses,
## fires that at the enemy, then folds back into the runes and closes.

enum Roll { FIREBALL, FIST, POISON }

const SPRITES_DIR: String = "res://Player/Abilities2.0/ShootAbilities/Riftbow/Sprites/"
const ROLL_SHEETS: Dictionary[Roll, String] = {Roll.FIREBALL: "RiftPortalFire.png", Roll.FIST: "RiftPortalFist.png", Roll.POISON: "RiftPortalPoison.png"}
## Sheet layout: opening frames first (closed runes -> fully open), then the swirl loop.
const OPEN_FRAMES: int = 9
const SWIRL_FRAMES: int = 16
const FIREBALL_PATH: String = "res://Enemies/WizardBoss/FireWizard/Fireball.tscn"
const POISON_CLOUD_PATH: String = "res://Player/Abilities2.0/PassiveAbilities/PoisonousGauge/PoisonousCloud.tscn"
const PULSE_COLOR: Color = Color(1.6, 1.6, 1.6)

@export var open_time: float = 0.35
@export var flash_time: float = 0.45
@export var close_time: float = 0.25
@export var portal_scale: float = 0.45
@export var swirl_fps: float = 18.0

var target: Enemy
## Where to fire if the target is dead or gone; follows the target while it lives.
var target_position: Vector2
var roll: Roll = Roll.FIREBALL
var damage: int = 1
var knockback: float = 200.0
var fist_knockback: float = 500.0
var _last_target_position: Vector2
var _sprite: Sprite2D
var _swirling: bool = false
var _swirl_time: float = 0.0

func _ready() -> void:
	z_index = 2
	_sprite = Sprite2D.new()
	_sprite.texture = load(SPRITES_DIR + ROLL_SHEETS[roll])
	_sprite.hframes = OPEN_FRAMES + SWIRL_FRAMES
	_sprite.frame = 0
	_sprite.scale = Vector2.ONE * portal_scale
	add_child(_sprite)
	_last_target_position = target_position
	if is_instance_valid(target) and not target.is_dead:
		_last_target_position = target.global_position
	_run()

func _process(delta: float) -> void:
	if _swirling:
		_swirl_time += delta
		_sprite.frame = OPEN_FRAMES + int(_swirl_time * swirl_fps) % SWIRL_FRAMES
	if is_instance_valid(target) and not target.is_dead:
		_last_target_position = target.global_position

func _run() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_open_frame, 0.0, 1.0, open_time)
	tween.tween_callback(_set_swirling.bind(true))
	# Telegraph: the sheet already shows what was rolled; pulse it before firing.
	for i in 3:
		tween.tween_property(_sprite, "modulate", PULSE_COLOR, flash_time / 6.0)
		tween.tween_property(_sprite, "modulate", Color.WHITE, flash_time / 6.0)
	tween.tween_callback(_fire)
	tween.tween_callback(_set_swirling.bind(false))
	tween.tween_method(_set_open_frame, 1.0, 0.0, close_time)
	tween.tween_callback(queue_free)

## 0 = closed runes, 1 = fully open.
func _set_open_frame(progress: float) -> void:
	_sprite.frame = clampi(roundi(progress * (OPEN_FRAMES - 1)), 0, OPEN_FRAMES - 1)

func _set_swirling(value: bool) -> void:
	_swirling = value

func _fire() -> void:
	var to_target: Vector2 = (_last_target_position - global_position).normalized()
	if to_target == Vector2.ZERO:
		to_target = Vector2.RIGHT
	match roll:
		Roll.FIREBALL:
			var fire_ball: FireBall = load(FIREBALL_PATH).instantiate()
			fire_ball.damage = damage
			fire_ball.knockback = knockback
			fire_ball.can_burn = true
			fire_ball.enemy_owned = false
			fire_ball.global_position = global_position
			fire_ball.launch(global_position, to_target)
			EventBus.summon_effect.emit(fire_ball)
		Roll.FIST:
			var fist: RiftFist = RiftFist.new()
			fist.damage = damage
			fist.knockback = fist_knockback
			fist.direction = to_target
			fist.global_position = global_position
			EventBus.summon_effect.emit(fist)
		Roll.POISON:
			var cloud: PoisonCloud = load(POISON_CLOUD_PATH).instantiate()
			cloud.global_position = _last_target_position
			cloud.emitting = true
			EventBus.summon_effect.emit(cloud)
