class_name GoldenAppleDartState extends EnemyState

## Darts in straight legs between random points, turning sharply at each one.
## After each leg it may stop to hover.

@onready var hover: GoldenAppleHoverState = $"../Hover"

var apple: GoldenApple
var _target: Vector2 = Vector2.ZERO

func init() -> void:
	apple = enemy as GoldenApple

func Enter() -> void:
	_target = apple.pick_dart_target()
	apple.set_flap_speed(apple.dart_flap_speed)

func Physics(delta: float) -> EnemyState:
	var speed: float = apple.flight_speed()
	var to_target: Vector2 = _target - apple.global_position
	if to_target.length() <= speed * delta:
		if randf() < apple.hover_chance:
			apple.velocity = Vector2.ZERO
			return hover
		_target = apple.pick_dart_target()
		to_target = _target - apple.global_position
	apple.velocity = to_target.normalized() * speed
	return null
