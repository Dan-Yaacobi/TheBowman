extends Area2D

signal player_fell

## When false, falling only respawns the player without losing a heart.
@export var costs_heart: bool = true

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.velocity.length() > 0:
			player_fell.emit()
			if not costs_heart:
				EventBus.respawn_player.emit()
				return
			var dead: bool = body.lose_heart()
			if dead:
				body.kill()
			else:
				EventBus.respawn_player.emit()
