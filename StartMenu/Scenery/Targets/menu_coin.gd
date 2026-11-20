class_name MenuCoin extends MenuTarget
## A coin planted on an island, slowly turning. When shot it pings, spins hard,
## pops up into the air, lands back in place and glitters.

@export var spin_speed: float = 1.6
@export var hit_spin_speed: float = 22.0
@export var pop_height: float = 14.0
@export var glitter_color: Color = Color(1.0, 0.9, 0.5)

var _rest: Vector2
var _angle: float = 0.0
var _speed: float = 0.0
var _pop_tween: Tween

func _ready() -> void:
	_rest = position
	_angle = randf() * TAU
	_speed = spin_speed

func _process(delta: float) -> void:
	_speed = move_toward(_speed, spin_speed, delta * 14.0)
	_angle += _speed * delta
	# A flat sprite turning on its vertical axis: never fully edge-on, so it stays readable.
	scale.x = maxf(absf(cos(_angle)), 0.2)

func react(arrow: MenuArrow, _local_point: Vector2) -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(arrow.rotation)
	arrow.reparent(get_parent())
	arrow.drop(Vector2(-direction.x * 8.0, -10.0), 50.0)
	play_hit_sound()
	flash(2.6, 0.3)
	_speed = hit_spin_speed
	if _pop_tween and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "position:y", _rest.y - pop_height, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "position:y", _rest.y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_glitter()

func _glitter() -> void:
	var glitter: CPUParticles2D = CPUParticles2D.new()
	glitter.amount = 8
	glitter.lifetime = 0.5
	glitter.one_shot = true
	glitter.explosiveness = 1.0
	glitter.direction = Vector2.UP
	glitter.spread = 180.0
	glitter.gravity = Vector2(0.0, 40.0)
	glitter.initial_velocity_min = 12.0
	glitter.initial_velocity_max = 30.0
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, glitter_color)
	ramp.set_color(1, Color(glitter_color, 0.0))
	glitter.color_ramp = ramp
	glitter.emitting = true
	glitter.position = position
	# On the parent, so the coin's spin squash doesn't squash the sparkles.
	get_parent().add_child(glitter)
	glitter.finished.connect(glitter.queue_free)
