class_name DebugOnly extends Node2D
## Children only exist in debug builds (editor runs). Removed from exported release builds.


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
