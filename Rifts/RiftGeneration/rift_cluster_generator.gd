class_name RiftClusterGenerator extends Node

var _nodes: Array[IslandNode]
var _config: RiftClusterConfig

func generate_cluster(config: RiftClusterConfig) -> Array[IslandNode]:
	_config = config
	_nodes = []

	# 1. create root / start node
	var root := IslandNode.new()
	root.depth = 0
	_nodes.append(root)

	# 2. DFS from root
	_dfs_create_children(0, 1) # parent index 0, depth 1

	# 3. layout positions in 2D
	_layout_nodes()

	# 4. tag special nodes (start/portal)
	_tag_special_nodes()

	return _nodes


func _dfs_create_children(parent_index: int, depth: int) -> void:
	# stop conditions
	if _nodes.size() >= _config.island_count:
		return
	if depth > _config.max_depth:
		return

	# how many children do we want to create for this parent?
	var remaining := _config.island_count - _nodes.size()
	if remaining <= 0:
		return

	var min_c: int= min(_config.min_children, remaining)
	var max_c: int = min(_config.max_children, remaining)

	var child_count := randi_range(min_c, max_c)

	for i in child_count:
		if _nodes.size() >= _config.island_count:
			break

		var child := IslandNode.new()
		child.parent = parent_index
		child.depth = depth

		var child_index := _nodes.size()
		_nodes.append(child)

		_nodes[parent_index].children.append(child_index)

		# DFS: immediately expand this child before siblings
		_dfs_create_children(child_index, depth + 1)

func _layout_nodes() -> void:
	if _nodes.is_empty():
		return

	# root / start node at origin
	_nodes[0].position = Vector2.ZERO

	# recursively layout the tree starting from root
	_layout_subtree(0)


func _layout_subtree(parent_index: int) -> void:
	var parent := _nodes[parent_index]
	var children := parent.children

	if children.is_empty():
		return

	var count := children.size()
	var half := (count - 1) / 2.0

	for i in range(count):
		var child_index := children[i]
		var child := _nodes[child_index]

		# base X: always move to the right from the parent
		var base_x := parent.position.x + _config.horizontal_step

		# base Y: spread siblings around the parent vertically
		var base_y := parent.position.y + (i - half) * _config.vertical_spacing

		var x := base_x + randf_range(-_config.horizontal_jitter, _config.horizontal_jitter)
		var y := base_y + randf_range(-_config.vertical_jitter, _config.vertical_jitter)

		y = clampf(y, _config.cluster_min_y, _config.cluster_max_y)
		# if you later add cluster_min_x / cluster_max_x, you can clamp x here too

		child.position = Vector2(x, y)

		# recurse into this child
		_layout_subtree(child_index)


func _tag_special_nodes() -> void:
	if _nodes.is_empty():
		return

	# start node is root (index 0)
	_nodes[0].type = "start"

	# find a leaf with greatest depth (good portal candidate)
	var best_idx := 0
	var best_depth := -1

	for i in _nodes.size():
		var node := _nodes[i]
		if node.children.is_empty() and node.depth > best_depth:
			best_depth = node.depth
			best_idx = i

	_nodes[best_idx].type = "portal_candidate"
	
#func build_rift(config: RiftClusterConfig) -> void:
	#var generator := RiftClusterGenerator.new()
	#var nodes := generator.generate_cluster(config)
#
	#for node in nodes:
		#var island := config.island_scene.instantiate()
		#island.position = node.position
		#add_child(island)
#
		## later:
		# island.setup_from_type(node.type)
		# or attach portal / chest / spawner, etc.
