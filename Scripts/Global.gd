# Global.gd corregido
extends Node

const MAX_INT = 9223372036854775807
const SAVE_FILE = "user://game_save.dat"  

var shader_enabled = true
var p1Position: Vector2
var nivel_actual = 1
var niveles_desbloqueados = []
var bloquear_menu = false # Variable para bloquear el acceso al menú
var in_menu = false # Variable para saber si estamos en el menú
var animation_in_progress = false # Nueva variable para controlar si hay animaciones en curso

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Inicializar con valores predeterminados
	niveles_desbloqueados = [true] # Al menos el primer nivel está desbloqueado
	
	# Intentar cargar datos guardados
	var loaded = cargar_datos()
	if not loaded:
		print("Creando nueva partida")
		# Guardar los valores predeterminados iniciales
		guardar_datos()
	
	# Conectar con AudioManager para saber cuándo se puede acceder al menú
	if AudioManager.has_signal("intro_finished"):
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
		"shader_enabled": shader_enabled
	}
	
	# Usamos store_string con JSON para mayor compatibilidad
	save_file.store_string(JSON.print(save_data))
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
		
	var content = save_file.get_as_text()
	save_file.close()
	
	# Verificar si el contenido es válido
	if content.empty():
		print("Archivo de guardado vacío")
		return false
	
	var parse_result = JSON.parse(content)
	if parse_result.error != OK:
		print("Error al analizar JSON: ", parse_result.error_string, " en línea ", parse_result.error_line)
		# Crear un nuevo archivo de guardado si el actual está corrupto
		borrar_guardado()
		return false
		
	var save_data = parse_result.result
	if typeof(save_data) == TYPE_DICTIONARY:
		if save_data.has("niveles_desbloqueados") and typeof(save_data.niveles_desbloqueados) == TYPE_ARRAY:
			niveles_desbloqueados = save_data.niveles_desbloqueados
		
		if save_data.has("shader_enabled") and typeof(save_data.shader_enabled) == TYPE_BOOL:
			shader_enabled = save_data.shader_enabled
			
		print("Datos cargados correctamente: ", niveles_desbloqueados)
		print("Estado del shader: ", shader_enabled)
		return true
	else:
		print("Formato de archivo incorrecto")
		return false

# Función para borrar el archivo de guardado corrupto
func borrar_guardado():
	var dir = Directory.new()
	if dir.file_exists(SAVE_FILE):
		dir.remove(SAVE_FILE)
		print("Archivo de guardado corrupto eliminado")

func _process(_delta):
	if Input.is_action_just_pressed("quit"):
		guardar_datos() # Guardar al salir
		get_tree().quit()
	
	if Input.is_action_just_pressed("menu"):
		if in_menu:
			# Si ya estamos en el menú, no hacer nada
			print("Ya estamos en el menú, ignorando acción de menú")
			return
			
		if bloquear_menu or animation_in_progress: 
			# No permitir ir al menú si está bloqueado o hay animaciones en curso
			print("Menú bloqueado: animación en curso o intro sonando")
			return
			
		# Si no hay bloqueos, procedemos normalmente
		AudioManager.pauseBGMusic()
		get_tree().paused = false
		# Usar TransitionManager para ir al menú con transición
		TransitionManager.go_to_menu()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# Guardar antes de salir
		guardar_datos()
		get_tree().quit()

func toggle_shader():
	shader_enabled = !shader_enabled
	guardar_datos() # Guardar inmediatamente al cambiar este ajuste
	print("Shader state: ", "ON" if shader_enabled else "OFF")

# Función para establecer el bloqueo del menú
func set_menu_blocked(blocked: bool):
	bloquear_menu = blocked
	print("Menú bloqueado: ", bloquear_menu)

# Función para establecer si estamos en el menú
func set_in_menu(value: bool):
	in_menu = value
	print("En menú: ", in_menu)
	
# Nueva función para controlar el estado de las animaciones
func set_animation_in_progress(in_progress: bool):
	animation_in_progress = in_progress
	print("Animación en curso: ", animation_in_progress)

# Función para verificar si se puede acceder al menú
func can_access_menu() -> bool:
	return !bloquear_menu && !animation_in_progress && !in_menu

# Global.desbloquear_todos_niveles(45)
#Solo se usa para desbloquear niveles (debug)

func desbloquear_todos_niveles(hasta_nivel: int = 10):
	# Asegurar que hay suficientes elementos en el array
	while niveles_desbloqueados.size() < hasta_nivel:
		niveles_desbloqueados.append(false)
	
	# Desbloquear todos los niveles hasta el nivel especificado
	for i in range(hasta_nivel):
		niveles_desbloqueados[i] = true
	
	# Guardar los cambios
	guardar_datos()
	print("Niveles desbloqueados hasta el nivel ", hasta_nivel)
	print("Estado actual de niveles: ", niveles_desbloqueados)
