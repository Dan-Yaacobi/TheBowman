class_name Hurricane extends Node2D

@export var base_speed: float = 40.0          # forward drift speed (px/sec)
@export var wander_strength: float = 0.7      # max meander off the target heading (radians)
@export var wander_frequency: float = 0.15    # how fast the meander evolves (lower = broader curves)
@export var lifetime: float = 8.0             # seconds before it dissipates (0 = never)

var direction: Vector2 = Vector2.RIGHT        # set this before/at instantiation
var _base_heading: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
var _age: float = 0.0

func _ready() -> void:
	_base_heading = direction.angle()          # lock the drift to the given direction
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = wander_frequency
	_noise.seed = randi()

func _process(delta: float) -> void:
	_age += delta
	if lifetime > 0.0 and _age >= lifetime:
		queue_free()
		return

	# Meander around the fixed target heading -- noise is centered on zero,
	# so it swings symmetrically to both sides and always returns.
	var wander: float = _noise.get_noise_1d(_age) * wander_strength
	var actual_heading: float = _base_heading + wander

	var velocity: Vector2 = Vector2.RIGHT.rotated(actual_heading) * base_speed
	global_position += velocity * delta
