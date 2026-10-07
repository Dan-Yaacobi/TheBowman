class_name PlayerBody extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var eyes_sprite: Sprite2D = $Sprite2D/Eyes

var touch_effects: Array[Callable] = []
var facing_direction: int = 1


func _process(_delta: float) -> void:
	if PlayerManager.player.shooting:
		eyes_sprite.frame = 1
	else:
		eyes_sprite.frame = 0
		blink()
	pass

func change_direction(_direction: bool) -> void:
	
	scale.x *= -1
	facing_direction *= -1

func blink() -> void:
	var random_chance = randi_range(0,200)
	if random_chance == 0:
		eyes_sprite.frame = 3
		await get_tree().create_timer(0.3).timeout
		eyes_sprite.frame = 0
		
func update_animation(anim: String) -> void:
	if anim == "":
		animation_player.stop()
	else:
		animation_player.play(anim)

func apply_touch_effects(_hurt_box: HurtBox, _damage, _result) -> void:
	return
	var enemy = _hurt_box.get_parent()
	if enemy is Enemy:
		apply_touch_burn(enemy)
		pass
const BURN_DEBUFF = preload("uid://caiebherwxilx")

func apply_touch_burn(_enemy: Enemy) -> void:
	if _enemy:
		var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
		burn_debuff.fire_damage = PlayerManager.player.stats.burn_damage.value()
		var duration = PlayerManager.player.stats.burn_duration.value()
		var ticks = PlayerManager.player.stats.burn_ticks.value()
		_enemy.debuff_handler.add_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID, duration, ticks)
