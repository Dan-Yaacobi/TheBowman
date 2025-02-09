class_name SpiderWeb extends Line2D

func _ready() -> void:
	width = 0.5
	#closed = true

func set_line(start_pos: Vector2, spider_pos: Vector2) -> void:
	set_point_position(0,Vector2(start_pos.x,start_pos.y - 1000))
	points.append(spider_pos)
