class_name ChallengeDef extends Resource

@export var display_name: String
@export_multiline var description: String
@export var goal: ChallengeGoal

@export var rewards: Array[EventReward] = []

@export_group("Spawning")
## Used by goals with continuous spawning. Waves define their own enemies.
@export var enemy_pool: Array[EnemyEntry] = []
@export var spawn_interval: float = 1.5
@export var max_alive: int = 5

@export_group("Modifiers")
## Always active for this challenge (e.g. the moving zone).
@export var modifiers: Array[ChallengeModifier] = []
## Curses the shrine can offer.
@export var curse_pool: Array[ChallengeCurse] = []
