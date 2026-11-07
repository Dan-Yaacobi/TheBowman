class_name GoldenAppleFleeState extends EnemyState

## Fast burst away from the player when hit, easing back to dart speed.

@onready var dart: GoldenAppleDartState = $"../Dart"

var apple: GoldenApple
var _direction: Vector2 = Vector2.ZERO
var _time_left: float = 0.0

func init() -> void:
	apple = enemy as GoldenApple

func Enter() -> void:
	restart()

## Called when hit again mid-flee.
func restart() -> void:
	_direction = apple.get_flee_direction()
	_time_left = apple.flee_duration

func Physics(delta: float) -> EnemyState:
	_time_left -= delta
	var speed: float = apple.flight_speed()
	var t: float = clampf(_time_left / apple.flee_duration, 0.0, 1.0)
	_bounce_off_edges()
	apple.velocity = _direction * lerpf(speed, speed * apple.flee_speed_multiplier, t)
	if _time_left <= 0.0:
		return dart
	return null

## Keeps the burst inside the flight area by reflecting off its edges.
func _bounce_off_edges() -> void:
	var rect: Rect2 = apple.get_flight_rect()
	var pos: Vector2 = apple.global_position
	if (pos.x < rect.position.x and _direction.x < 0.0) or (pos.x > rect.end.x and _direction.x > 0.0):
		_direction.x = -_direction.x
	if (pos.y < rect.position.y and _direction.y < 0.0) or (pos.y > rect.end.y and _direction.y > 0.0):
		_direction.y = -_direction.y
