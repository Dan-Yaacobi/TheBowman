class_name ImpPackData extends EnemyData
## An imp pack is an invisible spawner for a group of imps that rush the player together.

@export_subgroup("Pack")
@export var imp_scene: PackedScene
@export var imp_data: ImpData
@export var pack_size: int = 3
## Imps start spread this far apart
@export var spread: float = 14.0
