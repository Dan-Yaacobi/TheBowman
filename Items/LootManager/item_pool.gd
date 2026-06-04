class_name ItemPool extends Resource

@export var possible_stats: Array[StatRollDef] = []
@export var possible_textures: Array[Texture2D] = []  # roll one of these
@export var equipped_textures: Array[Texture2D] = []
@export var possible_display_names: Array[String] = []  # "Iron Bow", "Wind Bow" etc
@export var possible_abilities: Array[PlayerAbility] = []
@export var slot: EquipmentData.slots
@export var min_stat_count: int = 1
@export var max_stat_count: int = 3
@export var scale: float = 1.0
