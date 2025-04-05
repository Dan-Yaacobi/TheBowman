class_name Boss2PreAbility extends EnemyState

@onready var ability_activate: Boss2AbilityActivateState = $"../AbilityActivate"
@onready var pre_ability_location: Area2D = $"../../PreAbilityLocation"

@export var random_strength: float = 20.0
@export var shake_fade: float = 10.0
var go_to_ability: bool = false
var target_position: Vector2
var direction: Vector2
var done_shaking: bool
var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0
	
#what happens when we initialize this state
func init() -> void:
	pre_ability_location.body_entered.connect(finished)
	pass

#what happens when the player enters this state
func Enter() -> void:
	go_to_ability = false
	enemy.velocity = Vector2.ZERO
	var offset: Vector2 = Vector2([1,-1].pick_random() * randi_range(50,100),randi_range(-50,-80))
	target_position = enemy.player.global_position + offset
	pre_ability_location.global_position = target_position
	if pre_ability_location.overlaps_body(enemy):
		finished(enemy)
	direction = (target_position - enemy.global_position).normalized()
	done_shaking = false
	apply_shake()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	if not done_shaking:
		shake(_delta)
	else:
		enemy.velocity += direction * enemy.stats.move_speed * _delta * 15
		if go_to_ability:
		#if enemy.global_position.x > target_position.x - 10 and enemy.global_position.x < target_position.x + 10:
			return ability_activate
	return null
	
func finished(b: CharacterBody2D) -> void:
	if b is DemoEnemyBoss2:
		go_to_ability = true
	
func shake(_delta) -> void:

	if shake_strength > 0.05:
		shake_strength = lerpf(shake_strength, 0 , shake_fade * _delta)
		
		enemy.global_position += random_offset()
	else:
		done_shaking = true

func apply_shake() -> void:
	shake_strength = random_strength
	
func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
