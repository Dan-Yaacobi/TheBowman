class_name SacrificialAltarEvent extends Event

## The deeper the biome, the more the well asks and the better it pays.
## Per biome (earth, snow, hell): heart containers taken, and the rarity of the item given
## (0 Common, 1 Uncommon, 2 Epic, 3 Legendary).
@export var heart_cost_by_biome: Array[int] = [1, 2, 3]
@export var reward_rarity_by_biome: Array[int] = [1, 2, 3]

@onready var altar: SacrificialAltar = %SacrificialAltar
@onready var reward_marker: Marker2D = %RewardMarker

var _reward_rarity: int = 1

func _ready() -> void:
	var biome: int = CustomVariables.biome_index(current_rift_level())
	altar.set_heart_cost(heart_cost_by_biome[mini(biome, heart_cost_by_biome.size() - 1)])
	_reward_rarity = reward_rarity_by_biome[mini(biome, reward_rarity_by_biome.size() - 1)]
	altar.sacrificed.connect(_on_altar_sacrificed)

func _on_altar_sacrificed() -> void:
	var reward: EquipmentReward = EquipmentReward.new()
	reward.forced_rarity = _reward_rarity
	spawn_rewards(reward_marker.global_position, 0, [reward])
	report_finished(true)
