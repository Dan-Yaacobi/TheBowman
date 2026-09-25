extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.velocity.length() > 0:
			var dead: bool = body.lose_heart()
			if dead:
				body.kill()
			else:
				EventBus.respawn_player.emit()
