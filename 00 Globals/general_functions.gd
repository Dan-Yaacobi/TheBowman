extends Node

## Game speed outside hit freezes. Slow-motion effects (Hourglass Band) change it through
## set_time_scale_base so a hit freeze returns to the slowed speed instead of full speed.
var time_scale_base: float = 1.0
var _freezes: int = 0

func set_time_scale_base(scale: float) -> void:
	time_scale_base = scale
	if _freezes == 0:
		Engine.time_scale = scale

func hit_freeze(duration: float = 0.07) -> void:
	_freezes += 1
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	_freezes -= 1
	if _freezes == 0:
		Engine.time_scale = time_scale_base
