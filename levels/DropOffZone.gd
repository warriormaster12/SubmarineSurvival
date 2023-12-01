extends Area3D


var playerHasEntered: bool = false

func _on_body_entered(body:CharacterBody3D) -> void:
	if (!playerHasEntered && body.name == "PlayerShip"):
		print("player has arrived, goob jod")
		playerHasEntered = true
