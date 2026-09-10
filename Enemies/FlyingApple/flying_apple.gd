class_name FlyingApple extends Enemy

@onready var wings: Sprite2D = $Sprite2D/Wings

var wings_animation: AnimationPlayer

func extra_ready_functions() -> void:
	sprite.texture = stats.skin

	wings_animation  = $Sprite2D/Wings/WingsAnimation
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimation
	if wings_animation != null and stats.has_wings:
		wings.show()
		wings_animation.play("Fly")
	else:
		wings.hide()
	update_animation(stats.move_animation)
	for ability in stats.initial_ability:
		ability.activate_ability(self)
	state_machine.Initialize(self)
	
func _physics_process(_delta: float) -> void:
	face_the_player()
	move_and_slide()
	
func continue_extra_animation_players() -> void:
	if wings_animation:
		wings_animation.play()

func stop_extra_animation_players() -> void:
	if wings_animation:
		wings_animation.pause()
