class_name GeneratorData extends Resource

@export_range(1,200,1) var main_path_length: int = 10

@export_subgroup("Chunk Placement")
@export_range(1.0,10.0,0.25) var probability_decay: float = 2.0
@export_range(0.5,1.0,0.05) var main_bias: float = 0.75
@export_range(0.0,1.0,0.01) var final_bias: float = 0.33

@export_subgroup("Events")
## Events a portal can lead to, picked by weight (see EventEntry).
@export var event_entries: Array[EventEntry] = []
@export_range(0.0, 1.0) var event_chance: float = 0.5
@export var event_skip_start_chunks: int = 2
@export var event_skip_end_chunks: int = 2

@export_subgroup("Scroll Pedestals")
@export_range(0, 10) var scroll_pedestals_min: int = 1
@export_range(0, 10) var scroll_pedestals_max: int = 3
## Added to the island's EventPortalPosition marker so the pedestal stands on the surface.
@export var scroll_pedestal_offset: Vector2 = Vector2(0, 14)
