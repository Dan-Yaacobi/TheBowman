class_name RiftPortal extends Node2D
## Opens near an enemy already painted in the colour of what it rolled, pulses, then fires that at the enemy and closes.

enum Roll { FIREBALL, FIST, POISON }

const SPRITES_DIR: String = "res://Player/Abilities2.0/ShootAbilities/Riftbow/Sprites/"
const ROLL_SHEETS: Dictionary[Roll, String] = {Roll.FIREBALL: "RiftPortalFire.png", Roll.FIST: "RiftPortalFist.png", Roll.POISON: "RiftPortalPoison.png"}
const PORTAL_FRAMES: int = 16
const FIREBALL_PATH: String = "res://Enemies/WizardBoss/FireWizard/Fireball.tscn"
const POISON_CLOUD_PATH: String = "res://Player/Abilities2.0/PassiveAbilities/PoisonousGauge/PoisonousCloud.tscn"
const ROLL_COLORS: Dictionary[Roll, Color] = {Roll.FIREBALL: Color(1.0, 0.55, 0.15), Roll.FIST: Color(1.0, 0.2, 0.2), Roll.POISON: Color(0.4, 1.0, 0.3)}

@export var open_time: float = 0.15
@export var flash_time: float = 0.45
@export var close_time: float = 0.2
@export var portal_scale: float = 0.6
## Faster than the event portal (12) so it feels more violent.
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
var _swirl_time: float = 0.0

func _ready() -> void:
	z_index = 2
	_sprite = Sprite2D.new()
	_sprite.texture = load(SPRITES_DIR + ROLL_SHEETS[roll])
	_sprite.hframes = PORTAL_FRAMES
	_sprite.scale = Vector2.ZERO
	add_child(_sprite)
	_last_target_position = target_position
	if is_instance_valid(target) and not target.is_dead:
		_last_target_position = target.global_position
	_run()

func _process(delta: float) -> void:
	_swirl_time += delta
	_sprite.frame = int(_swirl_time * swirl_fps) % PORTAL_FRAMES
	if is_instance_valid(target) and not target.is_dead:
		_last_target_position = target.global_position

func _run() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", Vector2.ONE * portal_scale, open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Telegraph: the sheet already shows what was rolled; pulse it before firing.
	var flash_color: Color = ROLL_COLORS[roll]
	for i in 3:
		tween.tween_property(_sprite, "modulate", flash_color * 1.6, flash_time / 6.0)
		tween.tween_property(_sprite, "modulate", Color.WHITE, flash_time / 6.0)
	tween.tween_callback(_fire)
	tween.tween_property(_sprite, "scale", Vector2.ZERO, close_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

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
