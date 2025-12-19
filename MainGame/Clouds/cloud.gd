class_name Cloud extends CharacterBody2D
@onready var sprite: Sprite2D = $Sprite2D
@export var move_speed: float
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var exited_screen_timer: Timer = $VisibleOnScreenNotifier2D/ExitedScreenTimer

func _ready() -> void:
	visible_on_screen_notifier.screen_exited.connect(exited_the_screen)
	visible_on_screen_notifier.screen_entered.connect(entered_the_screen)
	exited_screen_timer.timeout.connect(queue_free)
	sprite.frame = randi_range(0 , sprite.hframes*sprite.vframes - 1)
	move_speed = randf_range(move_speed - 10, move_speed + 10)
	
func _physics_process(_delta: float) -> void:
	velocity.x = move_speed
	move_and_slide()

func entered_the_screen() -> void:
	if not exited_screen_timer.is_stopped():
		exited_screen_timer.stop()
	pass
	
func exited_the_screen() -> void:
	exited_screen_timer.start()
	pass
