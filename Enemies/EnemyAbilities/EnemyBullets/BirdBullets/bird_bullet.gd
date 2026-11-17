class_name BirdBullet extends EnemyBullet

## Physics layer 5 = "Wall" (islands).
const ISLAND_LAYER: int = 5

@onready var explosion_detector: Area2D = $Explosion/HurtBox2
@onready var explosion: CPUParticles2D = $Explosion
@onready var bullet_sprite: Sprite2D = $Sprite2D

var new_texture: Texture2D
@export var acceleration_rate: float = 1.0
## Fall speed cap, so the exponential acceleration can't run away
@export var max_fall_speed: float = 600.0
## Set on the hell bird's egg: the egg falls through islands and scorches the top of each one it crosses.
@export var island_burn_scene: PackedScene
## How long each scorched patch burns. Re-scorching a burning island resets it to this.
@export var scorch_lifetime: float = 3.5
## Burst played where the egg crosses an island's top (the telegraph)
@export var impact_scene: PackedScene
var _elapsed: float = 0.0

func _physics_process(delta: float) -> void:
	_elapsed += delta
	var current_speed: float = minf(data.move_speed * exp(acceleration_rate * _elapsed), max_fall_speed)
	
	global_position.y += current_speed * delta
func set_texture(texture: Texture2D) -> void:
	new_texture = texture
	
func extra_ready_function() -> void:
	scale*= 0.4
	bullet_sprite.texture = new_texture
	if island_burn_scene:
		set_collision_mask_value(ISLAND_LAYER, true)
		body_entered.connect(_on_body_entered)

## One patch per island: crossing an island that's already burning keeps it burning longer
## instead of adding another patch.
func _on_body_entered(body: Node2D) -> void:
	var island: Island = body as Island
	if island == null:
		return
	_play_impact(island)
	var burning: BurningIslandEffect = _find_burning(island)
	if burning:
		burning.keep_burning(scorch_lifetime)
		return
	var patch: BurningIslandEffect = island_burn_scene.instantiate()
	patch.field_lifetime = scorch_lifetime
	Enemy.copy_attack_tag(self, patch)
	patch.position = island.objects_spawn_markers.position
	island.call_deferred("add_child", patch)

## Ember burst on the island's top, right where the egg goes through (rides the island).
func _play_impact(island: Island) -> void:
	if impact_scene == null:
		return
	var impact: Node2D = impact_scene.instantiate()
	impact.position = island.to_local(Vector2(global_position.x, island.get_top_y()))
	island.add_child.call_deferred(impact)

func _find_burning(island: Island) -> BurningIslandEffect:
	for child: Node in island.get_children():
		if child is BurningIslandEffect and not child.is_queued_for_deletion():
			return child
	return null
	
func clear_shot(_var1, _var, _var3) -> void:
	explosion.emitting = true
	explosion_detector.monitoring = true
	sprite.visible = false
	explosion.call_deferred("reparent",get_parent())
	set_deferred("monitoring", false)
	queue_free()
