extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("glow_amount", 0.0)

	var aura_tween = create_tween()
	aura_tween.tween_property(mat, "shader_parameter/glow_amount", 1.0, 0.35)\
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	aura_tween.finished.connect(func():
		animation_player.play("Cast")
		aura_tween.tween_property(mat, "shader_parameter/glow_amount", 0.0, 0.35)
		)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
