extends Node

const MAX_INT = 9223372036854775807
const SAVE_FILE = "user://game_save.dat"  

# Constantes mejoradas para el control del joystick en Linux/Raspberry Pi
const JOYSTICK_MOUSE_SPEED_WINDOWS = 10.0  # Velocidad original para Windows
const JOYSTICK_MOUSE_SPEED_LINUX = 2.0     # Velocidad reducida para Linux/Raspberry Pi
const JOYSTICK_DEADZONE = 0.15             # Zona muerta ajustada
const JOYSTICK_MAX_SPEED_MULTIPLIER = 60   # Multiplicador máximo de velocidad (reducido de 100)

# Cambiar a botón X (el de la izquierda en Xbox controller)
const JOY_BUTTON_X = JOY_BUTTON_2  # Botón X en Xbox (el de la izquierda)
const JOY_BUTTON_A = JOY_BUTTON_0  # Botón A sigue siendo el inferior
const MOUSE_CLICK_DURATION = 0.1  # Duración del clic simulado en segundos

var joystick_click_timer = 0.0
var joystick_click_active = false

# Variables para ajuste dinámico de velocidad
var current_joystick_speed = JOYSTICK_MOUSE_SPEED_WINDOWS
var is_linux_system = false

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

# Variables para suavizado del movimiento en Linux
var joystick_velocity = Vector2.ZERO
var mouse_acceleration_factor = 1.0

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# Detectar el sistema operativo
	detect_system()
	
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

func detect_system():
	var os_name = OS.get_name()
	is_linux_system = (os_name == "X11" or os_name == "Linux")
	
	if is_linux_system:
		current_joystick_speed = JOYSTICK_MOUSE_SPEED_LINUX
		print("Sistema Linux detectado - usando velocidad reducida del joystick: ", current_joystick_speed)
	else:
		current_joystick_speed = JOYSTICK_MOUSE_SPEED_WINDOWS
		print("Sistema Windows detectado - usando velocidad estándar del joystick: ", current_joystick_speed)
	
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

func apply_joystick_curve(input_value: float) -> float:
	# Aplicar una curva exponencial para mejor control en valores bajos
	var abs_value = abs(input_value)
	var sign_value = sign(input_value)
	
	# Curva cuadrática para movimientos más suaves
	var curved_value = abs_value * abs_value * sign_value
	
	return curved_value

func handle_joystick_mouse_control(delta):
	# Obtener input del joystick derecho
	var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_2)  # Eje horizontal del joystick derecho
	var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_3)  # Eje vertical del joystick derecho
	
	# Aplicar zona muerta mejorada
	if abs(right_stick_x) < JOYSTICK_DEADZONE:
		right_stick_x = 0.0
	else:
		# Normalizar el valor después de aplicar la zona muerta
		right_stick_x = (right_stick_x - sign(right_stick_x) * JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
	
	if abs(right_stick_y) < JOYSTICK_DEADZONE:
		right_stick_y = 0.0
	else:
		# Normalizar el valor después de aplicar la zona muerta
		right_stick_y = (right_stick_y - sign(right_stick_y) * JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
	
	# Aplicar curva de respuesta para mejor control
	if is_linux_system:
		right_stick_x = apply_joystick_curve(right_stick_x)
		right_stick_y = apply_joystick_curve(right_stick_y)
	
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
		
		# Calcular el movimiento con velocidad ajustada según el sistema
		var movement_multiplier = current_joystick_speed * JOYSTICK_MAX_SPEED_MULTIPLIER * delta
		
		# Para Linux, aplicar suavizado adicional
		if is_linux_system:
			# Usar aceleración gradual en lugar de movimiento instantáneo
			var target_velocity = Vector2(right_stick_x, right_stick_y) * movement_multiplier
			joystick_velocity = joystick_velocity.linear_interpolate(target_velocity, 0.3)
			
			joystick_mouse_position += joystick_velocity
		else:
			# Movimiento directo para Windows
			joystick_mouse_position.x += right_stick_x * movement_multiplier
			joystick_mouse_position.y += right_stick_y * movement_multiplier
		
		# Limitar la posición a los bordes de la pantalla
		var viewport_size = get_viewport().size
		joystick_mouse_position.x = clamp(joystick_mouse_position.x, 0, viewport_size.x)
		joystick_mouse_position.y = clamp(joystick_mouse_position.y, 0, viewport_size.y)
		
		# Mover el ratón real a la posición virtual solo si es necesario
		var distance_to_real = joystick_mouse_position.distance_to(current_real_mouse_pos)
		if distance_to_real > 5.0:  # Solo mover si hay una diferencia significativa
			Input.warp_mouse_position(joystick_mouse_position)
		
		last_real_mouse_position = joystick_mouse_position
		
	else:
		# Resetear la velocidad cuando no hay input del joystick
		joystick_velocity = Vector2.ZERO
		
		if joystick_input_detected and not joystick_mouse_active:
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

# Función para ajustar manualmente la velocidad del joystick (útil para debug)
func set_joystick_speed(new_speed: float):
	current_joystick_speed = new_speed
	print("Velocidad del joystick ajustada a: ", current_joystick_speed)
	
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
