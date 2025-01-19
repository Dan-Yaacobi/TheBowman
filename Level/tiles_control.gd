class_name TilesControl extends TileMapLayer

const TORRENT = preload("res://Level/torrent.tscn")
var right_torrents: Array[Torrent]
var left_torrents: Array[Torrent]

var base_tile_index: int = 0
var right_tiles: Array[Vector2i] = [Vector2i.ZERO]
var left_tiles: Array[Vector2i] = [Vector2i.ZERO]
var right_most_tile_index: int = 1
var left_most_tile_index: int = 1

func _ready() -> void:
	pass

func get_limits() -> Rect2i:
	return get_used_rect()
	
func add_right_torrent(_tile: Vector2i) -> void:
	var new_torrent = TORRENT.instantiate()
	right_torrents.append(new_torrent)
	new_torrent.global_position = Vector2i(16 * _tile[0] + 8, -6)
	add_child(new_torrent)
	pass
	
func add_left_torrent(_tile: Vector2i) -> void:
	var new_torrent = TORRENT.instantiate()
	left_torrents.append(new_torrent)
	new_torrent.global_position = Vector2i(16 * (_tile[0] +1) - 8, -6)
	add_child(new_torrent)
	pass

func add_left_tile(_color: int) -> void:
	left_most_tile_index += 1
	var new_tile: Vector2i = Vector2i(-left_most_tile_index,0)
	set_cell(new_tile,_color,Vector2i(0,0))
	left_tiles.append(new_tile)
	pass
	
func add_right_tile(_color: int) -> void:
	right_most_tile_index += 1
	var new_tile: Vector2i = Vector2i(right_most_tile_index,0)
	set_cell(new_tile,_color,Vector2i(0,0))
	right_tiles.append(new_tile)
	pass
	
func remove_right_tile() -> void:
	set_cell(right_tiles.pop_back(),-1)
	right_most_tile_index -= 1
	pass

func remove_left_tile() -> void:
	set_cell(left_tiles.pop_back(),-1)
	left_most_tile_index -= 1
	pass

#func _unhandled_input(event: InputEvent) -> void:
#
	#if event.is_action_pressed("temp3"):
		#add_left_torrent(left_tiles[left_most_tile_index])
		#
	#if event.is_action_pressed("temp"):
		#add_left_tile(0)
		#
		#
	#if event.is_action_pressed("temp2"):
		#remove_left_tile()
		#
	#if event.is_action_pressed("temp"):
		#add_right_torrent(right_tiles[right_most_tile_index])
		#
	#if event.is_action_pressed("temp4"):
		#add_right_tile(0)
		#
		#
	#if event.is_action_pressed("temp3"):
		#remove_right_tile()
	##
	#pass
func _process(delta: float) -> void:
	pass

func remove_cell_at_point(_point: Vector2) -> void:
	set_cell(_point,-1,Vector2.ZERO)
	pass
	
