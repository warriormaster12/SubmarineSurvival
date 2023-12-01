extends Area3D


var playerHasEntered: bool = false

func _on_body_entered(body:CharacterBody3D) -> void:
	if (!playerHasEntered && body.name == "PlayerShip"):
		print("player has arrived, goob jod")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		body.GetNextCoordinates()
		playerHasEntered = true
