class_name SacrificialAltarEvent extends Event

@onready var altar: SacrificialAltar = %SacrificialAltar
@onready var reward_marker: Marker2D = %RewardMarker

func _ready() -> void:
	altar.sacrificed.connect(_on_altar_sacrificed)

func _on_altar_sacrificed() -> void:
	spawn_rewards(reward_marker.global_position)
