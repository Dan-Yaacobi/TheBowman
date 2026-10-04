class_name MovingTargetEvent extends ChallengeStoneEvent

@onready var target_routes: Node2D = $TargetRoutes

func _ready() -> void:
	super()
	challenge_started.connect(_on_challenge_started)
	challenge_finished.connect(_on_challenge_finished)

func get_routes() -> Array[TargetRoute]:
	var routes: Array[TargetRoute] = []
	for child: Node in target_routes.get_children():
		if child is TargetRoute:
			routes.append(child)
	return routes

func _on_challenge_started() -> void:
	PlayerManager.player.camera.zoom_out()

func _on_challenge_finished(_success: bool) -> void:
	PlayerManager.player.camera.zoom_in()
