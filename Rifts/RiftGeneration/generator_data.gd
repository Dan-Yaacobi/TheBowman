class_name GeneratorData extends Resource

@export_subgroup("Main Path")

## Number of chunks in the guaranteed main path to the portal
@export_range(1, 200, 1) var main_path_length: int = 8
## How many steps the generator may undo if main-path placement fails
@export_range(0, 3, 1) var main_backtrack_depth: int = 1

@export_subgroup("Difficulty / Branching")

## Difficulty level driving branching density, depth, and overall complexity
@export_range(1, 5, 1) var difficulty: int = 1
## Base number of chunks available for side branches (before difficulty scaling)
@export_range(0, 200, 1) var base_side_budget_nodes: int = 2
## Additional side-branch chunks added per difficulty level
@export_range(0, 50, 1) var side_budget_per_difficulty: int = 3
## Base probability for a branch to start from a main-path chunk
@export_range(0.0, 1.0, 0.01) var base_branch_start_main: float = 0.10
## Extra branch-start probability per difficulty level on the main path
@export_range(0.0, 1.0, 0.01) var branch_start_main_per_difficulty: float = 0.05
## Base probability for a branch to start from an existing branch
@export_range(0.0, 1.0, 0.01) var base_branch_start_branch: float = 0.02
## Extra branch-start probability per difficulty level on branches
@export_range(0.0, 1.0, 0.01) var branch_start_branch_per_difficulty: float = 0.02
## Base maximum recursion depth for branching (branch-off-branch)
@export_range(0, 6, 1) var max_branch_depth_base: int = 1
## Additional branch depth gained every two difficulty levels
@export_range(0, 6, 1) var max_branch_depth_per_two_difficulty: int = 1
## Base maximum length of any single branch
@export_range(1, 20, 1) var max_branch_len_base: int = 2
## Extra allowed branch length added per difficulty level
@export_range(0, 10, 1) var max_branch_len_per_difficulty: int = 1

@export_subgroup("Placement")
## How many chunk variants to try per exit marker before giving up
@export_range(1, 50, 1) var max_chunk_candidates_per_exit: int = 6
## Extra spacing added around chunk bounds to prevent tight overlaps
@export var bounds_padding: float = 6.0
## Minimum total chunks required; if not reached, generation is retried
@export_range(1, 200, 1) var min_total_chunks: int = 8
## How many full regeneration attempts are allowed before giving up
@export_range(1, 20, 1) var max_regen_attempts: int = 10
