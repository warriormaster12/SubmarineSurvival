extends Node
class_name ShipHealthSystem

@export var health: float = 100.0

var current_health:float = health:
	set(value):
		current_health = clampf(value, 0.0, health)
		on_health_changed.emit(current_health)
		if current_health <= 0.0:
			on_health_depleted.emit()

signal on_health_changed(value:float)
signal on_health_depleted

