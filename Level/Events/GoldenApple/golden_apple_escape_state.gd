class_name GoldenAppleEscapeState extends EnemyState

## Time's up: flies up and away from the player, speeding up and fading out,
## then the apple removes itself.

var apple: GoldenApple
var _direction: Vector2 = Vector2.UP
var _time_left: float = 0.0

func init() -> void:
	apple = enemy as GoldenApple

func Enter() -> void:
	_time_left = apple.escape_duration
	_direction = _get_escape_direction()
	var tween: Tween = apple.create_tween()
	tween.tween_property(apple, "modulate:a", 0.0, apple.escape_duration).set_ease(Tween.EASE_IN)

func Physics(delta: float) -> EnemyState:
	_time_left -= delta
	var t: float = 1.0 - clampf(_time_left / apple.escape_duration, 0.0, 1.0)
	apple.velocity = _direction * apple.flight_speed() * lerpf(1.0, apple.escape_speed_multiplier, t)
	if _time_left <= 0.0:
		apple.finish_escape()
	return null

## Mostly upwards, leaning away from the player.
func _get_escape_direction() -> Vector2:
	var player: Node2D = PlayerManager.player
	var side: float = 1.0 if randf() < 0.5 else -1.0
	if is_instance_valid(player):
		side = signf(apple.global_position.x - player.global_position.x)
		if is_zero_approx(side):
			side = 1.0
	return Vector2(side, -2.0).normalized()
