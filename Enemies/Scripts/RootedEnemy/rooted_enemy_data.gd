class_name RootedEnemyData extends EnemyData
## Shared tuning for enemies rooted on an island (pine tree, obsidian spire).

@export_subgroup("Rooted")
## Wakes when the player gets this close (pixels)
@export var wake_range: float = 150.0
## Goes back to sleep after the player has been further than this for sleep_delay seconds
@export var sleep_range: float = 220.0
@export var sleep_delay: float = 3.0
