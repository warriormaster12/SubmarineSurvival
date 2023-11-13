extends Node
class_name ShipHealthSystem

@export var health: float = 100.0

@onready var current_health:float = health:
	set(value):
		var depleting: bool = value < current_health
		current_health = clampf(value, 0.0, health)
		on_health_changed.emit(current_health, depleting)
		if current_health <= 0.0:
			on_health_depleted.emit()

signal on_health_changed(value:float, depleting: bool)
signal on_health_depleted
 
