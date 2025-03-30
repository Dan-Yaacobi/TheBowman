class_name SpiderWeb extends Line2D

func _ready() -> void:
	width = 0.5
	
#offset means where the web starts will be, so -1000 means it will start 
# 1000 pixel above the spider - the purpose is to make it seem like the line begins
# somewhere we cant see.

func set_line(start_pos: Vector2, spider_pos: Vector2,offset = 1000) -> void:
	set_point_position(0,Vector2(start_pos.x,start_pos.y - offset))
	points.append(spider_pos)
	
