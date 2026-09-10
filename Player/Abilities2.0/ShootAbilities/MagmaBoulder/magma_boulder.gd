class_name MagmaBoulder extends CharacterBody2D

@onready var hurt_box: HurtBox = $HurtBox
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var queue_free_timer: Timer = $VisibleOnScreenNotifier2D/QueueFreeTimer

const BURN_DEBUFF = preload("uid://caiebherwxilx")

var gravity: int = 120
var speed: float = 100
var direction: Vector2
var damage: int = 1

func _ready() -> void:
	velocity = speed * direction
	hurt_box.base_damage = damage
	hurt_box.add_effect(apply_burn)
	visible_on_screen_notifier.screen_exited.connect(attempt_to_queue_free)
	visible_on_screen_notifier.screen_entered.connect(stop_exiting)
	queue_free_timer.timeout.connect(queue_free)
	
func _physics_process(delta: float) -> void:
	velocity.y += gravity*delta
	rotate(5*delta)
	move_and_slide()

func stop_exiting() -> void:
	queue_free_timer.stop()
	
func attempt_to_queue_free() -> void:
	queue_free_timer.start()
	
func apply_burn(enemy: Enemy) -> void:
	var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
	burn_debuff.set_damage(roundi(damage*0.2))
	enemy.apply_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID,5,5)
