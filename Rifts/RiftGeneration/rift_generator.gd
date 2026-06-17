class_name RiftGenerator extends Node2D

@export var data: GeneratorData
@export var library: RiftChunkLibrary
const RIFT_LEVEL = preload("uid://dye8vshx06jjw")
const BOUNDS_LAYER: int = 15
const FALLING_DEATH = preload("uid://dre264ek5xw44")

signal rift_created(RiftLevel)
var rift_level: RiftLevel
var main_path_chunks: Array[RiftChunk] = []

var enemy_spawn_streak: int = 0
var max_spawn_streak: int = 1

var biased_towards: CustomVariables.directions
var rng = RandomNumberGenerator.new()
var placed_bounds: Array[Bounds]
var side_path_terminal_chunks: Array[RiftChunk] = []
var lowest_chunk: RiftChunk
#Generator Invariants:
#1. Each traversal chunk has 3 exit markers, and each exit marker has a different direction

func generate(_curr_level: int) -> RiftLevel:
	main_path_chunks = []
	placed_bounds = []
	rift_level = RIFT_LEVEL.instantiate()
	add_child(rift_level)
	build_main_path(_curr_level)
	return rift_level
	
func manage_lowest_chunk(chunk: RiftChunk) -> void:
	lowest_chunk = chunk

func add_death_area() -> void:
	if lowest_chunk:
		var falling_death: Area2D = FALLING_DEATH.instantiate()
		falling_death.global_position = Vector2(0, lowest_chunk.global_position.y + 500)
		rift_level.add_child(falling_death)
	
func build_main_path(_curr_level: int) -> void:
	var intro_chunk: IntroChunk = library.get_intro_chunk().scene.instantiate()
	rift_level.add_child(intro_chunk)
	manage_lowest_chunk(intro_chunk)
	
	placed_bounds.append(intro_chunk.bounds)
	rift_level.starting_chunk = intro_chunk
	main_path_chunks.append(intro_chunk)
	var last_chunk: RiftChunk = build_path(data.main_path_length, intro_chunk, true)
	if !last_chunk:
		reset()
		generate(_curr_level)
		return
	else:
		if not place_end_portal(main_path_chunks[-1]):
			if not place_end_portal(main_path_chunks[-2]):
				reset()
				generate(_curr_level)
				return
		build_all_side_paths(2, main_path_chunks)
		rift_created.emit(rift_level)
		add_death_area()
		EventBus.finished_loading.emit()

func build_all_side_paths(amount: int, chunks: Array[RiftChunk]) -> void:
	var done: int = 0
	var attempting_chunks = chunks.duplicate()
	attempting_chunks.shuffle()
	while done < amount:
		if attempting_chunks.is_empty():
			break
		var starting_chunk: RiftChunk = attempting_chunks.pop_back()
		if build_side_path(starting_chunk):
			done += 1

func build_side_path(_start_chunk: RiftChunk) -> bool:
	## length needs better adjustments
	var length: int = int(data.main_path_length)
	var last_chunk: RiftChunk = build_path(length,_start_chunk, false)
	if !last_chunk:
		return false
	side_path_terminal_chunks.append(last_chunk)
	last_chunk.is_side_path_terminal = true
	place_treasure_island(last_chunk)
	rift_level.side_path_terminal_chunks.append(last_chunk)
	return true

func spawn_something(_chunk: RiftChunk) -> void:
	if _chunk:
		# find available exits and pick one
		# roll something to spawn
		# try to spawn it
		# if successful, mark exit as un available and use spawn budget
		# if it fails, try a different exit
		# if there are no exits left available -> return
		pass
	pass
	
func build_path(_max_length: int, _starting_chunk: RiftChunk, _main_path: bool = true, _first_exit: ExitMarker = null) -> RiftChunk:
	var length: int = 0
	var _curr_chunk: RiftChunk = _starting_chunk
	var _prev_chunk: RiftChunk = _curr_chunk
	var chunks: Array[RiftChunk] = main_path_chunks
	
	if not _main_path:
		chunks = []
	
	#first exit is random if none provided
	var exit: ExitMarker
	
	if not _first_exit:
		var exits: Array[ExitMarker] = _curr_chunk.get_exit_markers()
		if exits.size() > 0:
			exit = exits.pick_random()
	else:
		exit = _first_exit
	var _i = -1
	while(length <= _max_length):
		_i+=1
		var next_chunk: RiftChunk = try_to_add_chunk(exit)
		
		if next_chunk:
			next_chunk.is_main_path = _main_path
			chunks.append(next_chunk)
			if _main_path:
				rift_level.main_path_chunks.append(next_chunk)
				
			_prev_chunk = _curr_chunk
			_curr_chunk = next_chunk
			length += 1
			exit.disable()
			exit = pick_exit(_curr_chunk, exit.direction, chunks, _max_length)
			if not exit:
				return null # This means there was a bug where a chunk was designed without 3 exits and a direction for each
		else:
			if exit:
				exit.disable()
			
			var exits: Array[ExitMarker] = _curr_chunk.get_exit_markers()
			if exits.size() > 0:
				exit = exits.pick_random()
			else:
				if chunks.size() == 1:
					_curr_chunk.queue_free()
					return null ## getting here means we are the first chunk and have no available exits
					
				if _curr_chunk == _starting_chunk:
					return null
					
				_curr_chunk.queue_free()
				placed_bounds.erase(_curr_chunk.bounds)
				_curr_chunk = _prev_chunk
				chunks.pop_back()
				if chunks.size() < 2:
					return null
				_prev_chunk = chunks[chunks.size() - 2]
				length -= 1
	return chunks[_max_length]

func pick_exit(_curr_chunk: RiftChunk, _direction: CustomVariables.directions, _chunks: Array, _length: int) -> ExitMarker:
	
	var weighted_direction_dic: Dictionary[CustomVariables.directions,float] ={
	CustomVariables.directions.Up: 0.25,
	CustomVariables.directions.Left: 0.25,
	CustomVariables.directions.Down: 0.25,
	CustomVariables.directions.Right: 0.25
	}

	#get the direction for the next exit.
	var bias: CustomVariables.directions = _direction
	var bias_offset: float = float(_chunks.size()) / float(_length)
	var main_bias: float = data.main_bias
	var zero_bias: float = 0.0
	var final_bias: float = data.final_bias
	
	main_bias = max(final_bias, main_bias - (main_bias - final_bias) * bias_offset * data.probability_decay)
	weighted_direction_dic[bias] = main_bias
	weighted_direction_dic[(bias + 2)% 4] = zero_bias
	weighted_direction_dic[(bias + 1) % 4] = (1 - main_bias)/2
	weighted_direction_dic[(bias + 3) % 4] = (1 - main_bias)/2
	
	var direction: CustomVariables.directions = (
		weighted_direction_dic.keys()[
			rng.rand_weighted(weighted_direction_dic.values())
			]
		)
		
	var exits: Array[ExitMarker] = _curr_chunk.get_exit_markers()
	for exit in exits:
		if exit.direction == direction:
			return exit
	return exits.pick_random()
	
func try_to_add_chunk(_exit: ExitMarker, type: ChunkData.types = ChunkData.types.TRAVERSAL) -> RiftChunk:
	if not is_instance_valid(_exit):
		return null
		
	var chunks: Array[ChunkData]
	
	if type == ChunkData.types.TRAVERSAL:
		chunks = library.get_all_traversal_chunks(_exit.direction).duplicate()
		chunks.shuffle()
		
	elif type == ChunkData.types.PORTAL:
		chunks = library.get_portal_chunk().duplicate()

	elif type == ChunkData.types.TREASURE:
		chunks = library.get_treasure_chunk().duplicate()
		chunks.shuffle()
		
	while chunks.size() > 0:
		var chunk_node: RiftChunk = chunks.pop_back().scene.instantiate()
		rift_level.add_child(chunk_node)
		
		if not is_instance_valid(_exit):
			chunk_node.queue_free()
			return null
		
		chunk_node.global_position = _exit.global_position - chunk_node.entry.position
		
		var overlaps: bool = false
		overlaps = check_overlapping_bounds(chunk_node)
		
		if not overlaps:
			placed_bounds.append(chunk_node.bounds)
			chunk_node.set_rift_level(rift_level)
			if lowest_chunk == null or chunk_node.global_position.y > lowest_chunk.global_position.y:
				manage_lowest_chunk(chunk_node)
			return chunk_node
		else:
			chunk_node.queue_free()
	
	return null

func place_treasure_island(last_chunk: RiftChunk) -> bool:
	for exit in last_chunk.get_exit_markers():
		if try_to_add_chunk(exit,ChunkData.types.TREASURE):
			return true
	return false
		
func place_end_portal(last_chunk: RiftChunk) -> bool:
	for exit in last_chunk.get_exit_markers():
		if try_to_add_chunk(exit,ChunkData.types.PORTAL):
			return true
	return false

func check_overlapping_bounds(_chunk_node: RiftChunk, _checking_bounds: Array[Bounds] = placed_bounds) -> bool:
	for exisiting_bounds in placed_bounds:
		if _chunk_node.bounds.intersects_with(exisiting_bounds):
			return true
	return false
	
func place_key() -> void:
	pass
func spawn_enemies() -> void:
	pass

func reset() -> void:
	rift_level.queue_free()
