class_name RiftClusterConfig extends Resource

## Island scene to instance for each node.
@export var island_scene: Array[PackedScene]

## Target number of islands in this Rift cluster.
@export var island_count: int = 20

## Maximum depth (number of "steps") from start to the furthest leaf.
## Higher = longer paths.
@export var max_depth: int = 5

## Minimum number of children per node (if there is room for more islands).
@export var min_children: int = 1

## Maximum number of children per node (soft cap, still limited by island_count).
@export var max_children: int = 3

## Base horizontal distance between depth levels (root->children).
@export var horizontal_step: float = 220.0

## Random horizontal jitter per node, to avoid perfect grid.
@export var horizontal_jitter: float = 40.0

## Base vertical spacing between siblings at the same depth.
@export var vertical_spacing: float = 140.0

## Random vertical jitter per node.
@export var vertical_jitter: float = 40.0

## Vertical bounds for the entire cluster.
@export var cluster_min_y: float = -300.0
@export var cluster_max_y: float =  300.0
