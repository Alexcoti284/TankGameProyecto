extends Node

# Constants
const MAX_INT = 9223372036854775807 # 2^63 - 1

# Global variables
var p1Position: Vector2
var nivel_actual = 1  # Guarda el nivel en curso
var niveles_desbloqueados = []

func desbloquear_nivel(nivel: int):
	if nivel > niveles_desbloqueados.size():
		niveles_desbloqueados.resize(nivel)  # Expande el array si es necesario
		niveles_desbloqueados.fill(false)  # Asegura que los nuevos índices sean `false`
	
	niveles_desbloqueados[nivel - 1] = true  # Desbloquea el nivel

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Asegurar que el primer nivel esté desbloqueado
	niveles_desbloqueados.resize(1)  
	niveles_desbloqueados[0] = true

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
