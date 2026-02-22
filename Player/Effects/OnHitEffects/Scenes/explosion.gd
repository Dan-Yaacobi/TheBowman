class_name Explosion extends Node2D

@onready var spark = $Spark
@onready var explosion = $Explosion
@onready var hurt_box = $HurtBox

func _ready() -> void:
	hurt_box.set_text_color(Color.DARK_ORANGE)
	hurt_box.monitoring = true
	explosion.emitting = true
	explosion.finished.connect(finished)
	

func finished() -> void:
	queue_free()
