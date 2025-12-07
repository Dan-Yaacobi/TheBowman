class_name CloudEnemy extends Enemy
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var hit_box: EnemyHitBox = $HitBox

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	damaged_animation_player = $Sprite2D/DamagedAnimationPlayer
	enemy_state_machine.Initialize(self)
	hit_box.set_enemy(self)
	
func _physics_process(delta: float) -> void:
	move_and_slide()
