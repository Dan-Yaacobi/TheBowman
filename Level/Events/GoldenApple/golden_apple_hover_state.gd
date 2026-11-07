class_name GoldenAppleHoverState extends EnemyState

## Hovers obliviously in place, bobbing. The opening to shoot.

const BOB_SPEED: float = 12.0
const BOB_FREQUENCY: float = 1.5

@onready var dart: GoldenAppleDartState = $"../Dart"

var apple: GoldenApple
var _time_left: float = 0.0
var _bob_time: float = 0.0

func init() -> void:
	apple = enemy as GoldenApple

func Enter() -> void:
	_time_left = apple.hover_time()
	_bob_time = 0.0
	apple.set_flap_speed(apple.hover_flap_speed)

func Physics(delta: float) -> EnemyState:
	_bob_time += delta
	_time_left -= delta
	apple.velocity = Vector2(0.0, sin(_bob_time * TAU * BOB_FREQUENCY) * BOB_SPEED)
	if apple.is_player_near() or _time_left <= 0.0:
		return dart
	return null
