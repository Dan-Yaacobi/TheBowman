class_name SlipperySurface extends Area2D
## Makes the ground slippery for the player while their body overlaps this area.
## Give it a CollisionShape2D that covers the top of the surface, and mask the Player layer.

## Share of normal ground grip kept: 1 = normal, 0 = no grip at all
@export_range(0.0, 1.0) var traction: float = 0.12

var _players: Array[Player] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	tree_exiting.connect(_release_all)

func set_traction(value: float) -> void:
	traction = value
	for player: Player in _players:
		if is_instance_valid(player):
			player.add_traction_source(self, traction)

func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or _players.has(player):
		return
	_players.append(player)
	player.add_traction_source(self, traction)

func _on_body_exited(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null:
		return
	_players.erase(player)
	player.remove_traction_source(self)

# The surface owns its cleanup: leaving the tree never leaves the player stuck on ice
func _release_all() -> void:
	for player: Player in _players:
		if is_instance_valid(player):
			player.remove_traction_source(self)
	_players.clear()
