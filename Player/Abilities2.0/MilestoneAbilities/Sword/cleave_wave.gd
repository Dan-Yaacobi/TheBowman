class_name CleaveWave extends HurtBox
## The Cleave Wave crescent: flies straight, hits each enemy and breakable object it touches once, fades out.

const ENEMIES_LAYER: int = 3
const OBJECTS_LAYER: int = 4
const OUTLINE_COLOR: Color = Color(0.13, 0.1, 0.09, 0.9)
const FILL_COLOR: Color = Color(1.0, 0.93, 0.78)

var direction: Vector2 = Vector2.RIGHT
var travel: float = 34.0
var duration: float = 0.2
## Half the crescent's height (hit area and drawing).
var radius: float = 15.0
## Half the hit area's thickness along the travel direction.
var thickness: float = 7.0

var _age: float = 0.0

func _ready() -> void:
	super._ready()
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(ENEMIES_LAYER, true)
	set_collision_mask_value(OBJECTS_LAYER, true)
	monitorable = false
	rotation = direction.angle()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = thickness
	capsule.height = radius * 2.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	shape.shape = capsule
	add_child(shape)
	z_index = 1

func _physics_process(delta: float) -> void:
	_age += delta
	var t: float = _age / duration
	if t >= 1.0:
		queue_free()
		return
	global_position += direction * (travel / duration) * delta
	modulate.a = 1.0 - t * t
	queue_redraw()

## A thin crescent bulging forward: dark outline under a light blade line, pixel style (no antialiasing).
func _draw() -> void:
	var center: Vector2 = Vector2(-radius * 0.7, 0.0)
	var half_angle: float = PI / 2.6
	draw_arc(center, radius, -half_angle, half_angle, 10, OUTLINE_COLOR, 4.0)
	draw_arc(center, radius, -half_angle, half_angle, 10, FILL_COLOR, 2.0)
