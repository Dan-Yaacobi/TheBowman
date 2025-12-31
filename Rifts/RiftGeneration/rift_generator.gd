class_name RiftGenerator extends Node2D

@export var data: GeneratorData
@export var library: RiftChunkLibrary
@export var intro_data: ChunkData


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _side_budget_left: int = 0
var _max_branch_depth: int = 1

# used exits: key=ExitMarker instance_id (int), value=true
var _used_exit_ids: Dictionary = {}

# placed rects for collision (padded)
var _placed_rects: Array[Rect2] = []

var _total_chunks: int = 0

class PlacementRecord:
	var chunk: RiftChunk
	var exit_id: int
	var rect: Rect2

	func _init(c: RiftChunk, e_id: int, r: Rect2) -> void:
		chunk = c
		exit_id = e_id
		rect = r

func generate() -> RiftChunk:
	_rng.randomize()
	_side_budget_left = data.base_side_budget_nodes + data.side_budget_per_difficulty * data.difficulty
	_max_branch_depth = data.max_branch_depth_base + int(floor(float(data.difficulty) / 2.0)) * data.max_branch_depth_per_two_difficulty
	var attempt: int = 0
	while attempt < data.max_regen_attempts:
		_reset_world()

		var intro: RiftChunk = _spawn_chunk(intro_data)
		if intro == null:
			return null

		intro.global_position = global_position
		_register_bounds(intro)

		var main_chain: Array[RiftChunk] = _build_main_path(intro, data.main_path_length)
		_try_branch_recursive(main_chain, 1)

		if _total_chunks >= data.min_total_chunks and main_chain.size() >= 2:
			print("RiftGen OK: total=", _total_chunks, " main=", main_chain.size(), " side_left=", _side_budget_left)
			return intro

		attempt += 1
	
	# Last resort: return whatever we got (or null if you prefer)
	print("RiftGen FAILSAFE HIT: total=", get_child_count())
	return _spawn_chunk(intro_data)# (don’t do this; keep intro from last attempt if you want)


# ------------------------------------------------------------
# Main path
# ------------------------------------------------------------

func _build_main_path(start: RiftChunk, length: int) -> Array[RiftChunk]:
	var chain: Array[RiftChunk] = []
	chain.append(start)

	if length <= 1:
		return chain

	var records: Array[PlacementRecord] = [] # records for chunks AFTER start
	var target: int = length

	while chain.size() < target:
		var parent: RiftChunk = chain[chain.size() - 1]

		var rec: PlacementRecord = _try_attach_new_chunk(parent, ChunkData.types.TRAVERSAL, 1)
		if rec != null:
			chain.append(rec.chunk)
			records.append(rec)
			continue

		# No place: bounded backtrack
		if data.main_backtrack_depth <= 0:
			break

		var back: int = 0
		var placed_after_start: int = records.size()
		var did_recover: bool = false

		while back < data.main_backtrack_depth and placed_after_start > 0 and not did_recover:
			var last_rec: PlacementRecord = records.pop_back()
			_remove_placement(last_rec)
			chain.pop_back()
			placed_after_start -= 1
			back += 1

			parent = chain[chain.size() - 1]
			rec = _try_attach_new_chunk(parent, ChunkData.types.TRAVERSAL, 1)
			if rec != null:
				chain.append(rec.chunk)
				records.append(rec)
				did_recover = true

		if not did_recover:
			break

	return chain

# ------------------------------------------------------------
# Recursive branching (scrambled order)
# ------------------------------------------------------------

func _try_branch_recursive(nodes: Array[RiftChunk], current_depth: int) -> void:
	if _side_budget_left <= 0:
		return
	if current_depth > _max_branch_depth:
		return
	if nodes.is_empty():
		return

	var shuffled: Array[RiftChunk] = _shuffled_chunks(nodes)

	var p_start: float = 0.0
	if current_depth == 1:
		p_start = data.base_branch_start_main + data.branch_start_main_per_difficulty * float(data.difficulty)
	else:
		p_start = data.base_branch_start_branch + data.branch_start_branch_per_difficulty * float(data.difficulty)

	for n: RiftChunk in shuffled:
		if _side_budget_left <= 0:
			return

		if _rng.randf() > p_start:
			continue

		var branch_len: int = _pick_branch_length()
		if branch_len <= 0:
			continue

		# Choose purpose (placeholder for later)
		var purpose: ChunkData.types = _choose_branch_purpose(current_depth)

		# Start a branch by attaching the first chunk
		var first_rec: PlacementRecord = _try_attach_new_chunk(n, purpose, 1)
		if first_rec == null:
			continue

		_side_budget_left -= 1
		if _side_budget_left < 0:
			_side_budget_left = 0

		var branch_chain: Array[RiftChunk] = []
		branch_chain.append(first_rec.chunk)

		# Extend to full length (or stop on failure)
		_extend_branch_chain(branch_chain, branch_len - 1, purpose)

		# Only after branch is built, try branching off it (recursive)
		_try_branch_recursive(branch_chain, current_depth + 1)

func _extend_branch_chain(chain: Array[RiftChunk], extra: int, purpose: ChunkData.types) -> void:
	var remaining: int = extra
	while remaining > 0 and _side_budget_left > 0:
		var parent: RiftChunk = chain[chain.size() - 1]
		var rec: PlacementRecord = _try_attach_new_chunk(parent, purpose, 1)
		if rec == null:
			return

		chain.append(rec.chunk)

		_side_budget_left -= 1
		if _side_budget_left < 0:
			_side_budget_left = 0

		remaining -= 1

# ------------------------------------------------------------
# Placement: ExitMarker-as-socket + bounds (no jitter)
# ------------------------------------------------------------

func _try_attach_new_chunk(parent: RiftChunk, desired_type: ChunkData.types, desired_difficulty: int) -> PlacementRecord:
	var exits: Array[ExitMarker] = _get_free_exits(parent)
	if exits.is_empty():
		return null

	var shuffled_exits: Array[ExitMarker] = _shuffled_exits(exits)

	for exit_marker: ExitMarker in shuffled_exits:
		var exit_id: int = int(exit_marker.get_instance_id())
		var tried_ids: Dictionary = {} # ChunkData.id -> true
		var attempts: int = 0

		while attempts < data.max_chunk_candidates_per_exit:
			var chunk_data: ChunkData = _pick_chunk_data(desired_type, desired_difficulty, tried_ids)
			if chunk_data == null:
				break

			var child: RiftChunk = _spawn_chunk(chunk_data)
			if child == null:
				attempts += 1
				continue

			# Snap EntryMarker to ExitMarker position
			var target: Vector2 = exit_marker.global_position
			var delta: Vector2 = target - child.get_entry_global()
			child.global_position += delta

			var rect: Rect2 = _get_padded_bounds(child)
			if _rect_collides(rect):
				child.queue_free()
				attempts += 1
				continue

			_used_exit_ids[exit_id] = true
			_register_rect(rect)
			_total_chunks += 1
			var rec: PlacementRecord = PlacementRecord.new(child, exit_id, rect)
			return rec

	return null

func _get_free_exits(chunk: RiftChunk) -> Array[ExitMarker]:
	var result: Array[ExitMarker] = []
	var exits: Array[ExitMarker] = chunk.get_exit_markers()

	for e: ExitMarker in exits:
		var eid: int = int(e.get_instance_id())
		if _used_exit_ids.has(eid):
			continue
		result.append(e)

	return result

func _pick_chunk_data(desired_type: ChunkData.types, desired_difficulty: int, tried_ids: Dictionary) -> ChunkData:
	var pool: Array[ChunkData] = []

	for c: ChunkData in library.chunks:
		if c == null:
			continue
		if c.type != desired_type:
			continue
		if c.difficulty != desired_difficulty:
			continue
		if tried_ids.has(c.id):
			continue
		pool.append(c)

	if pool.is_empty():
		return null

	var total: float = 0.0
	for c: ChunkData in pool:
		total += max(0.0, c.weight)

	var picked: ChunkData = null
	if total <= 0.0:
		var idx: int = _rng.randi_range(0, pool.size() - 1)
		picked = pool[idx]
	else:
		var r: float = _rng.randf() * total
		var acc: float = 0.0
		for c: ChunkData in pool:
			acc += max(0.0, c.weight)
			if r <= acc:
				picked = c
				break
		if picked == null:
			picked = pool[pool.size() - 1]

	tried_ids[picked.id] = true
	return picked

# ------------------------------------------------------------
# Purpose + length knobs
# ------------------------------------------------------------

func _choose_branch_purpose(current_depth: int) -> ChunkData.types:
	# Placeholder for later (TREASURE/COMBAT/EVENT/etc)
	return ChunkData.types.TRAVERSAL

func _pick_branch_length() -> int:
	var max_len: int = data.max_branch_len_base + data.max_branch_len_per_difficulty * data.difficulty
	if max_len < 1:
		max_len = 1

	var r: float = _rng.randf()

	# Weighted short (tune later)
	if r < 0.50:
		return 1
	if r < 0.80:
		return min(2, max_len)
	if r < 0.95:
		return min(3, max_len)

	if max_len <= 3:
		return max_len

	return _rng.randi_range(4, max_len)

# ------------------------------------------------------------
# Bounds / collision helpers
# ------------------------------------------------------------

func _get_padded_bounds(chunk: RiftChunk) -> Rect2:
	var r: Rect2 = chunk.get_bounds_rect()
	if data.bounds_padding <= 0.0:
		return r
	return Rect2(r.position - Vector2(data.bounds_padding, data.bounds_padding), r.size + Vector2(data.bounds_padding * 2.0, data.bounds_padding * 2.0))

func _rect_collides(candidate: Rect2) -> bool:
	for r: Rect2 in _placed_rects:
		if candidate.intersects(r):
			return true
	return false

func _register_bounds(chunk: RiftChunk) -> void:
	var rect: Rect2 = _get_padded_bounds(chunk)
	_register_rect(rect)

func _register_rect(rect: Rect2) -> void:
	_placed_rects.append(rect)

func _remove_placement(rec: PlacementRecord) -> void:
	# free exit marker
	if rec.exit_id != 0 and _used_exit_ids.has(rec.exit_id):
		_used_exit_ids.erase(rec.exit_id)

	# remove rect (first match)
	var i: int = 0
	while i < _placed_rects.size():
		if _placed_rects[i] == rec.rect:
			_placed_rects.remove_at(i)
			break
		i += 1

	# delete chunk
	if rec.chunk != null and is_instance_valid(rec.chunk):
		rec.chunk.queue_free()

# ------------------------------------------------------------
# Spawn / reset
# ------------------------------------------------------------

func _spawn_chunk(chunk_data: ChunkData) -> RiftChunk:
	if chunk_data == null or chunk_data.scene == null:
		return null

	var inst: Node = chunk_data.scene.instantiate()
	add_child(inst)

	var chunk: RiftChunk = inst as RiftChunk
	chunk.set_rift(get_parent())
	if chunk == null:
		inst.queue_free()
		return null
	return chunk

func _reset_world() -> void:
	_used_exit_ids.clear()
	_placed_rects.clear()
	_total_chunks = 0
	var kids: Array[Node] = get_children()
	for c: Node in kids:
		c.queue_free()

# ------------------------------------------------------------
# Shuffle helpers
# ------------------------------------------------------------

func _shuffled_chunks(arr: Array[RiftChunk]) -> Array[RiftChunk]:
	var out: Array[RiftChunk] = []
	for v: RiftChunk in arr:
		out.append(v)

	var i: int = out.size() - 1
	while i > 0:
		var j: int = _rng.randi_range(0, i)
		var tmp: RiftChunk = out[i]
		out[i] = out[j]
		out[j] = tmp
		i -= 1

	return out

func _shuffled_exits(arr: Array[ExitMarker]) -> Array[ExitMarker]:
	var out: Array[ExitMarker] = []
	for v: ExitMarker in arr:
		out.append(v)

	var i: int = out.size() - 1
	while i > 0:
		var j: int = _rng.randi_range(0, i)
		var tmp: ExitMarker = out[i]
		out[i] = out[j]
		out[j] = tmp
		i -= 1

	return out
