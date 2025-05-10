extends Node

const MAX_INT = 9223372036854775807
const SAVE_FILE = "user://game_save.dat"  

var shader_enabled = true
var p1Position: Vector2
var nivel_actual = 1
var niveles_desbloqueados = []
var bloquear_menu = false # Variable para bloquear el acceso al menú
var in_menu = false # Variable para saber si estamos en el menú

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	var loaded = cargar_datos()
	if not loaded:
		print("Creando nueva partida")
	
	# Asegurar que el primer nivel esté desbloqueado
	if niveles_desbloqueados.size() == 0:
		niveles_desbloqueados.append(true)
	else:
		niveles_desbloqueados[0] = true
		
	# Conectar con AudioManager para saber cuándo se puede acceder al menú
	if not AudioManager.is_connected("intro_finished", self, "_on_intro_finished"):
		AudioManager.connect("intro_finished", self, "_on_intro_finished")
	
func _on_intro_finished():
	bloquear_menu = false
	print("Menú desbloqueado")

func desbloquear_nivel(nivel: int):
	# Asegurar que el array tiene suficiente tamaño
	while niveles_desbloqueados.size() < nivel:
		niveles_desbloqueados.append(false)
	
	# Desbloquear el nivel
	niveles_desbloqueados[nivel - 1] = true
	
	# Guardar los cambios
	guardar_datos()
	print("Nivel desbloqueado: ", nivel)
	print("Estado de niveles: ", niveles_desbloqueados)
	
func guardar_datos():
	var save_file = File.new()
	var error = save_file.open(SAVE_FILE, File.WRITE)
	if error != OK:
		print("Error al guardar datos: ", error)
		return false
	
	var save_data = {
		"niveles_desbloqueados": niveles_desbloqueados,
		"shader_enabled": shader_enabled  # Guarda también el estado del shader
	}
	
	save_file.store_var(save_data)
	save_file.close()
	print("Datos guardados correctamente")
	return true
	
func cargar_datos():
	var save_file = File.new()
	if not save_file.file_exists(SAVE_FILE):
		print("No existe archivo de guardado")
		return false
		
	var error = save_file.open(SAVE_FILE, File.READ)
	if error != OK:
		print("Error al cargar datos: ", error)
		return false
		
	var save_data = save_file.get_var()
	save_file.close()
	
	if save_data:
		if save_data.has("niveles_desbloqueados"):
			niveles_desbloqueados = save_data["niveles_desbloqueados"]
		
		# Carga el estado del shader si existe
		if save_data.has("shader_enabled"):
			shader_enabled = save_data["shader_enabled"]
			
		print("Datos cargados correctamente: ", niveles_desbloqueados)
		print("Estado del shader: ", shader_enabled)
		return true
	else:
		print("Formato de archivo incorrecto")
		return false

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_just_pressed("menu"):
		if in_menu:
			# Si ya estamos en el menú, no hacer nada
			print("Ya estamos en el menú, ignorando acción de menú")
			return
			
		if not bloquear_menu: # Solo ir al menú si no está bloqueado
			AudioManager.pauseBGMusic()
			get_tree().paused = false
			# Usar TransitionManager para ir al menú con transición
			TransitionManager.go_to_menu()
		else:
			print("Menú bloqueado mientras suena la intro")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# Guardar antes de salir
		guardar_datos()
		get_tree().quit()

func toggle_shader():
	shader_enabled = !shader_enabled
	print("Shader toggled: ", shader_enabled)

# Función para establecer el bloqueo del menú
func set_menu_blocked(blocked: bool):
	bloquear_menu = blocked
	print("Menú bloqueado: ", bloquear_menu)

# Función para establecer si estamos en el menú
func set_in_menu(value: bool):
	in_menu = value
	print("En menú: ", in_menu)
