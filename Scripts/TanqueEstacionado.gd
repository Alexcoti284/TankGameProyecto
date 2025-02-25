extends "res://Scripts/TanqueEnemigo.gd"

const maxCanviarDireccionTiempo = 5.0

func _ready():
	$TiempoCanvioDireccion.wait_time = rng.randf_range(0, maxCanviarDireccionTiempo)

func _on_TiempoCanvioDireccion_timeout():
	rotacionDireccion = -rotacionDireccion
	$TiempoCanvioDireccion.wait_time = rng.randf_range(0, maxCanviarDireccionTiempo)
