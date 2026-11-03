class_name StormRod extends Node2D
## A lightning rod stuck in an enemy. Owned by the enemy, so it disappears with it.

const ROD_PATH: String = "res://Player/Abilities2.0/ShootAbilities/Stormcaller/Sprites/LightningRod.png"

var enemy: Enemy
var age: float = 0.0
var spent: bool = false
var _sprite: Sprite2D

static func plant(_enemy: Enemy) -> StormRod:
	var rod: StormRod = StormRod.new()
	rod.enemy = _enemy
	rod.position = Vector2(4, -6)
	_enemy.add_child(rod)
	return rod

func _ready() -> void:
	z_index = 4
	rotation = deg_to_rad(20.0)
	_sprite = Sprite2D.new()
	_sprite.texture = load(ROD_PATH)
	_sprite.scale = Vector2(0.45, 0.45)
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	add_child(_sprite)
	scale = Vector2(1.6, 1.6)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.12)

func is_alive() -> bool:
	return not spent and not is_queued_for_deletion() and is_instance_valid(enemy) and not enemy.is_dead

## The point lightning connects to (the rod's tip).
func tip() -> Vector2:
	return _sprite.to_global(Vector2(0, -_sprite.texture.get_height())) if _sprite else global_position

func spark() -> void:
	_sprite.modulate = Color(1.6, 1.8, 2.2)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)

func spend() -> void:
	if spent:
		return
	spent = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
