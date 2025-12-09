class_name FallingDeath extends Area2D

func enabled() -> void:
	monitoring = true
	monitorable = true

func disabled() -> void:
	monitoring = false
	monitorable = false
