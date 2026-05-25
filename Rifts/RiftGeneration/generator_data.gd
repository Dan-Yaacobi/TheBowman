class_name GeneratorData extends Resource

@export_range(1,200,1) var main_path_length: int = 10

@export_subgroup("Chunk Placement")
@export_range(1.0,10.0,0.25) var probability_decay: float = 2.0
@export_range(0.5,1.0,0.05) var main_bias: float = 0.75
@export_range(0.0,1.0,0.01) var final_bias: float = 0.33
