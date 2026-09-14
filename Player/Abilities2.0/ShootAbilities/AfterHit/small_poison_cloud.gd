extends Node2D

@onready var poison_cloud: PoisonCloud = $PoisonCloud

func _ready() -> void:
	poison_cloud.emitting = true
