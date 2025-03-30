extends Node

const MAX_INT = 9223372036854775807
const SAVE_FILE = "user://game_save.dat"

var p1Position: Vector2
var nivel_actual = 1
var niveles_desbloqueados = []

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	cargar_datos()
	
	# Asegurar que el primer nivel esté desbloqueado
	if niveles_desbloqueados.size() == 0:
		niveles_desbloqueados.append(true)
	else:
		niveles_desbloqueados[0] = true

func desbloquear_nivel(nivel: int):
	# Asegurar que el array tiene suficiente tamaño
	while niveles_desbloqueados.size() < nivel:
		niveles_desbloqueados.append(false)
	
	# Desbloquear el nivel
	niveles_desbloqueados[nivel - 1] = true
	
	# Guardar los cambios
	guardar_datos()
	
func guardar_datos():
	var save_file = File.new()
	save_file.open(SAVE_FILE, File.WRITE)
	
	var save_data = {
		"niveles_desbloqueados": niveles_desbloqueados
	}
	
	save_file.store_var(save_data)
	save_file.close()
	
func cargar_datos():
	var save_file = File.new()
	if not save_file.file_exists(SAVE_FILE):
		return
		
	save_file.open(SAVE_FILE, File.READ)
	var save_data = save_file.get_var()
	save_file.close()
	
	if save_data and save_data.has("niveles_desbloqueados"):
		niveles_desbloqueados = save_data["niveles_desbloqueados"]

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
