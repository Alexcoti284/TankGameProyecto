extends Node

const MAX_INT = 9223372036854775807
const SAVE_FILE = "user://game_save.dat"  

# Añadir nuevas constantes para el control del joystick
const JOYSTICK_MOUSE_SPEED = 10.0  # Velocidad del movimiento del ratón
const JOYSTICK_DEADZONE = 0.2      # Zona muerta para evitar drift

# Cambiar a botón X (el de la izquierda en Xbox controller)
const JOY_BUTTON_X = JOY_BUTTON_2  # Botón X en Xbox (el de la izquierda)
const JOY_BUTTON_A = JOY_BUTTON_0  # Botón A sigue siendo el inferior
const MOUSE_CLICK_DURATION = 0.1  # Duración del clic simulado en segundos

var joystick_click_timer = 0.0
var joystick_click_active = false

var shader_enabled = true
var p1Position: Vector2
var nivel_actual = 1
var niveles_desbloqueados = []
var bloquear_menu = false
var in_menu = false
var animation_in_progress = false

# Variables para estadísticas (sin cambios)
var total_deaths = 0
var total_time = 0.0
var session_start_time = 0.0
var level_start_time = 0.0

# Variables para el control del ratón con joystick
var joystick_mouse_active = false
var joystick_mouse_position = Vector2.ZERO
var last_real_mouse_position = Vector2.ZERO  # Para recordar la última posición real del ratón

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Resto de inicialización (sin cambios)
	niveles_desbloqueados = [true]
	session_start_time = OS.get_ticks_msec() / 1000.0
	level_start_time = session_start_time
	
	var loaded = cargar_datos()
	if not loaded:
		print("Creando nueva partida")
		guardar_datos()
	
	if AudioManager.has_signal("intro_finished"):
		if not AudioManager.is_connected("intro_finished", self, "_on_intro_finished"):
			AudioManager.connect("intro_finished", self, "_on_intro_finished")
	
	# Inicializar posición del ratón virtual con la posición actual del ratón
	var current_mouse_pos = get_viewport().get_mouse_position()
	joystick_mouse_position = current_mouse_pos
	last_real_mouse_position = current_mouse_pos
	
func _on_intro_finished():
	bloquear_menu = false
	print("Menú desbloqueado")

# Nueva función para reiniciar el tiempo del nivel
func reset_level_time():
	level_start_time = OS.get_ticks_msec() / 1000.0

# Nueva función para obtener el tiempo del nivel actual
func get_current_level_time() -> float:
	return (OS.get_ticks_msec() / 1000.0) - level_start_time

# Nueva función para obtener el tiempo total de juego
func get_total_time() -> float:
	var current_session_time = (OS.get_ticks_msec() / 1000.0) - session_start_time
	return total_time + current_session_time

# Nueva función para incrementar muertes
func increment_deaths():
	total_deaths += 1
	guardar_datos()  # Guardar inmediatamente cuando muere
	print("Total de muertes: ", total_deaths)

# Nueva función para formatear tiempo en MM:SS
func format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]

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
	# Actualizar el tiempo total antes de guardar
	var current_session_time = (OS.get_ticks_msec() / 1000.0) - session_start_time
	var time_to_save = total_time + current_session_time
	
	var save_file = File.new()
	var error = save_file.open(SAVE_FILE, File.WRITE)
	if error != OK:
		print("Error al guardar datos: ", error)
		return false
	
	var save_data = {
		"niveles_desbloqueados": niveles_desbloqueados,
		"shader_enabled": shader_enabled,
		"total_deaths": total_deaths,
		"total_time": time_to_save
	}
	
	# Usamos store_string con JSON para mayor compatibilidad
	save_file.store_string(JSON.print(save_data))
	save_file.close()
	print("Datos guardados correctamente")
	print("Tiempo total guardado: ", format_time(time_to_save))
	print("Muertes totales guardadas: ", total_deaths)
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
		
		# Cargar estadísticas nuevas
		if save_data.has("total_deaths") and typeof(save_data.total_deaths) == TYPE_REAL:
			total_deaths = int(save_data.total_deaths)
		elif save_data.has("total_deaths") and typeof(save_data.total_deaths) == TYPE_INT:
			total_deaths = save_data.total_deaths
		
		if save_data.has("total_time") and typeof(save_data.total_time) == TYPE_REAL:
			total_time = save_data.total_time
		elif save_data.has("total_time") and typeof(save_data.total_time) == TYPE_INT:
			total_time = float(save_data.total_time)
			
		print("Datos cargados correctamente: ", niveles_desbloqueados)
		print("Estado del shader: ", shader_enabled)
		print("Muertes totales cargadas: ", total_deaths)
		print("Tiempo total cargado: ", format_time(total_time))
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

func _process(delta):
	# Manejar la salida del juego (sin cambios)
	if Input.is_action_just_pressed("quit"):
		guardar_datos()
		get_tree().quit()
	
	# Manejar el menú (sin cambios)
	if Input.is_action_just_pressed("menu"):
		if in_menu:
			return
		if bloquear_menu or animation_in_progress: 
			return
		AudioManager.pauseBGMusic()
		get_tree().paused = false
		TransitionManager.go_to_menu()
	
	# Control del ratón con joystick derecho
	handle_joystick_mouse_control(delta)
	
	# Manejar el clic con el botón X (izquierdo)
	handle_joystick_click(delta)
	
	
func get_mouse_pos() -> Vector2:
	return joystick_mouse_position if joystick_mouse_active else (
		get_tree().root.get_viewport().get_mouse_position() if get_tree() and get_tree().root 
		else Vector2.ZERO
	)

func handle_joystick_click(delta):
	# Detectar si se presionó el botón X (izquierdo)
	if Input.is_joy_button_pressed(0, JOY_BUTTON_X) and not joystick_click_active:
		# Simular clic del ratón
		var mouse_event = InputEventMouseButton.new()
		mouse_event.button_index = BUTTON_LEFT
		mouse_event.pressed = true
		mouse_event.position = get_mouse_pos()
		Input.parse_input_event(mouse_event)
		
		joystick_click_active = true
		joystick_click_timer = MOUSE_CLICK_DURATION
	elif not Input.is_joy_button_pressed(0, JOY_BUTTON_X) and joystick_click_active:
		# Liberar el clic del ratón
		var mouse_event = InputEventMouseButton.new()
		mouse_event.button_index = BUTTON_LEFT
		mouse_event.pressed = false
		mouse_event.position = get_mouse_pos()
		Input.parse_input_event(mouse_event)
		
		joystick_click_active = false
		joystick_click_timer = 0.0
	
	# Temporizador para clics mantenidos
	if joystick_click_active:
		joystick_click_timer -= delta
		if joystick_click_timer <= 0:
			# Mantener el clic "presionado" mientras se mantenga el botón
			joystick_click_timer = MOUSE_CLICK_DURATION
			var mouse_event = InputEventMouseButton.new()
			mouse_event.button_index = BUTTON_LEFT
			mouse_event.pressed = true
			mouse_event.position = get_mouse_pos()
			Input.parse_input_event(mouse_event)
			
func handle_joystick_mouse_control(delta):
	# Obtener input del joystick derecho
	var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_2)  # Eje horizontal del joystick derecho
	var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_3)  # Eje vertical del joystick derecho
	
	# Aplicar zona muerta
	if abs(right_stick_x) < JOYSTICK_DEADZONE:
		right_stick_x = 0.0
	if abs(right_stick_y) < JOYSTICK_DEADZONE:
		right_stick_y = 0.0
	
	# Detectar movimiento del ratón físico
	var current_real_mouse_pos = get_viewport().get_mouse_position()
	var mouse_moved_physically = current_real_mouse_pos.distance_to(last_real_mouse_position) > 10.0
	
	# Detectar cualquier input del joystick (incluyendo botones)
	var joystick_input_detected = (right_stick_x != 0.0 or right_stick_y != 0.0 or 
		Input.is_joy_button_pressed(0, JOY_BUTTON_X))
	
	# Si hay input del joystick, activar el control del ratón virtual
	if right_stick_x != 0.0 or right_stick_y != 0.0:
		# Si no estaba activo el control por joystick, inicializar con la posición actual del ratón
		if not joystick_mouse_active:
			joystick_mouse_position = current_real_mouse_pos
		
		joystick_mouse_active = true
		
		# Mover la posición virtual del ratón
		joystick_mouse_position.x += right_stick_x * JOYSTICK_MOUSE_SPEED * 100 * delta
		joystick_mouse_position.y += right_stick_y * JOYSTICK_MOUSE_SPEED * 100 * delta
		
		# Limitar la posición a los bordes de la pantalla
		var viewport_size = get_viewport().size
		joystick_mouse_position.x = clamp(joystick_mouse_position.x, 0, viewport_size.x)
		joystick_mouse_position.y = clamp(joystick_mouse_position.y, 0, viewport_size.y)
		
		# Mover el ratón real a la posición virtual
		Input.warp_mouse_position(joystick_mouse_position)
		last_real_mouse_position = joystick_mouse_position
		
	elif joystick_input_detected and not joystick_mouse_active:
		# Si se presiona un botón del joystick pero no estaba en modo joystick, activarlo
		joystick_mouse_active = true
		joystick_mouse_position = current_real_mouse_pos
		last_real_mouse_position = current_real_mouse_pos
		
	elif mouse_moved_physically and not joystick_input_detected:
		# Solo cambiar a modo ratón si no hay input del joystick Y el ratón se movió físicamente
		joystick_mouse_active = false
		joystick_mouse_position = current_real_mouse_pos
		last_real_mouse_position = current_real_mouse_pos

# Función para verificar si el cursor está siendo controlado por joystick
func is_joystick_mouse_active() -> bool:
	return joystick_mouse_active

# Función para obtener la posición del cursor controlado por joystick
func get_joystick_mouse_position() -> Vector2:
	return joystick_mouse_position
	
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
