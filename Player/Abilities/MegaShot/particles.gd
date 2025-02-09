extends CPUParticles2D

var total_rad: float
var acceleration_factor: int

func start(_time: float) -> void:
	acceleration_factor = 50
	total_rad = _time*acceleration_factor

	emitting = true
	color = Color.CRIMSON
	color.a = 0
	pass

func stop() -> void:
	emitting = false
	
func _physics_process(delta: float) -> void:
	if emitting:
		radial_accel_min -= delta*acceleration_factor
		color.a += delta
		if radial_accel_min <= - total_rad:
			acceleration_factor = 0
			color = Color.FOREST_GREEN
	else:
		radial_accel_min = 0
