extends "res://Scripts/TanqueEnemigo.gd"


const maxChangeDirectionTime = 5.0

func _ready():
	$TiempoCanvioDireccion.wait_time = rng.randf_range(0, maxChangeDirectionTime)



func _on_TiempoCanvioDireccion_timeout():
	rotationDirection = -rotationDirection
	$TiempoCanvioDireccion.wait_time = rng.randf_range(0, maxChangeDirectionTime)
