class_name RiftPortal extends Node2D
## Opens near an enemy, flashes the colour of what it rolled, then fires that at the enemy and closes.

enum Roll { FIREBALL, FIST, POISON }

const PORTAL_PATH: String = "res://Player/Abilities2.0/ShootAbilities/Riftbow/Sprites/RiftPortal.png"
const FIREBALL_PATH: String = "res://Enemies/WizardBoss/FireWizard/Fireball.tscn"
const POISON_CLOUD_PATH: String = "res://Player/Abilities2.0/PassiveAbilities/PoisonousGauge/PoisonousCloud.tscn"
const ROLL_COLORS: Dictionary[Roll, Color] = {Roll.FIREBALL: Color(1.0, 0.55, 0.15), Roll.FIST: Color(1.0, 0.2, 0.2), Roll.POISON: Color(0.4, 1.0, 0.3)}

@export var open_time: float = 0.15
@export var flash_time: float = 0.45
@export var close_time: float = 0.2
@export var portal_scale: float = 0.45

var target: Enemy
var roll: Roll = Roll.FIREBALL
var damage: int = 1
var knockback: float = 200.0
var fist_knockback: float = 500.0
var _last_target_position: Vector2
var _sprite: Sprite2D

func _ready() -> void:
	z_index = 2
	_sprite = Sprite2D.new()
	_sprite.texture = load(PORTAL_PATH)
	_sprite.scale = Vector2.ZERO
	add_child(_sprite)
	if is_instance_valid(target):
		_last_target_position = target.global_position
	_run()

func _process(delta: float) -> void:
	_sprite.rotation += delta * 3.0
	if is_instance_valid(target) and not target.is_dead:
		_last_target_position = target.global_position

func _run() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", Vector2.ONE * portal_scale, open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Telegraph: flash what was rolled.
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
