class_name BirdBullet extends EnemyBullet

## Physics layer 5 = "Wall" (islands).
const ISLAND_LAYER: int = 5

@onready var explosion_detector: Area2D = $Explosion/HurtBox2
@onready var explosion: CPUParticles2D = $Explosion
@onready var bullet_sprite: Sprite2D = $Sprite2D

var new_texture: Texture2D
@export var acceleration_rate: float = 1.0
## Set on the hell bird's egg: the egg falls through islands and scorches the top of each one it crosses.
@export var island_burn_scene: PackedScene
## How long each scorched patch burns.
@export var scorch_lifetime: float = 3.5
var _elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var current_speed: float = data.move_speed * exp(acceleration_rate * _elapsed)
	
	global_position.y += current_speed * delta
func set_texture(texture: Texture2D) -> void:
	new_texture = texture
	
func extra_ready_function() -> void:
	scale*= 0.4
	bullet_sprite.texture = new_texture
	if island_burn_scene:
		set_collision_mask_value(ISLAND_LAYER, true)
		body_entered.connect(_on_body_entered)

## One patch per island: an island that is already burning is skipped.
func _on_body_entered(body: Node2D) -> void:
	var island: Island = body as Island
	if island == null or _is_burning(island):
		return
	var patch: BurningIslandEffect = island_burn_scene.instantiate()
	patch.field_lifetime = scorch_lifetime
	Enemy.copy_attack_tag(self, patch)
	patch.position = island.objects_spawn_markers.position
	island.call_deferred("add_child", patch)

func _is_burning(island: Island) -> bool:
	for child: Node in island.get_children():
		if child is BurningIslandEffect and not child.is_queued_for_deletion():
			return true
	return false
	
func clear_shot(_var1, _var, _var3) -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	sprite.visible = false
	explosion.call_deferred("reparent",get_parent())
	set_deferred("monitoring", false)
	queue_free()
