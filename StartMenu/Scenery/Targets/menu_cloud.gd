class_name MenuCloud extends MenuTarget
## A cloud drifting across the scenery, wrapping around when it leaves the view.
## Arrows fly straight through, parting a little puff on the way.

@export var drift_speed: float = 4.0
## Horizontal range the cloud wraps within, in its parent's coordinates.
@export var wrap_range: Vector2 = Vector2(-80.0, 770.0)
@export var puff_color: Color = Color(1.0, 0.85, 0.85, 0.9)

func _process(delta: float) -> void:
	position.x += drift_speed * delta
	var half_width: float = get_rect().size.x * 0.5
	if drift_speed > 0.0 and position.x - half_width > wrap_range.y:
		position.x = wrap_range.x - half_width
	elif drift_speed < 0.0 and position.x + half_width < wrap_range.x:
		position.x = wrap_range.y + half_width

func on_passed_through(local_point: Vector2) -> void:
	var puff: CPUParticles2D = CPUParticles2D.new()
	puff.position = local_point
	puff.amount = 10
	puff.lifetime = 0.8
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.spread = 180.0
	puff.gravity = Vector2.ZERO
	puff.initial_velocity_min = 8.0
	puff.initial_velocity_max = 18.0
	puff.damping_min = 15.0
	puff.damping_max = 25.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 4.0
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, puff_color)
	ramp.set_color(1, Color(puff_color, 0.0))
	puff.color_ramp = ramp
	puff.emitting = true
	add_child(puff)
	puff.finished.connect(puff.queue_free)
