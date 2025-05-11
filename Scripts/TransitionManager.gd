extends Node

# Señales
signal transition_completed
signal transition_mid_point
signal level_loaded  # Señal para indicar que el nivel está listo

# Escena de transición
const LevelTransitionScene = preload("res://Escenas/Gui/LevelTransition.tscn")

# Instancia actual de la transición
var transition_instance = null
var transition_in_progress = false

# Variable para seguir el último destino
var last_destination = ""
var level_is_ready = false  # Variable para controlar si el nivel está listo

func _ready():
	# Asegurar que este nodo no se pause cuando el juego se pause
	pause_mode = Node.PAUSE_MODE_PROCESS

# Añadir parámetro animate_numbers para controlar la animación de números
func change_level(from_level: int, to_level: int, show_numbers: bool = true, animate_numbers: bool = true):
	# Asegurarse de que no hay otra transición en curso
	if transition_in_progress:
		print("Transición ya en curso, ignorando solicitud")
		return
		
	transition_in_progress = true
	level_is_ready = false  # Reiniciar estado del nivel
	
	# Informar a Global que hay una animación en curso
	if Global:
		Global.set_animation_in_progress(true)
	
	# Notificar a AudioManager sobre la transición
	if AudioManager:
		AudioManager.start_level_transition()
	
	# Detectar si es un reinicio del mismo nivel
	var is_restart = (from_level == to_level && from_level > 0)
	
	print("Iniciando transición de nivel ", from_level, " a ", to_level, 
		  " (mostrar números: ", show_numbers, ", animar números: ", animate_numbers, 
		  ", es reinicio: ", is_restart, ")")
	
	# Obtener árbol de escenas
	var scene_tree = get_tree()
	if scene_tree == null:
		transition_in_progress = false
		if Global:
			Global.set_animation_in_progress(false)
		if AudioManager:
			AudioManager.end_level_transition()
		return
		
	# Crear instancia de transición
	transition_instance = LevelTransitionScene.instance()
	scene_tree.get_root().add_child(transition_instance)
	
	# Configurar transición
	transition_instance.show_numbers = show_numbers
	transition_instance.animate_numbers = animate_numbers
	transition_instance.max_levels = 100  # Ajustar según el juego
	
	# Conectar las señales de transición
	if not transition_instance.is_connected("transition_completed", self, "_on_transition_completed"):
		transition_instance.connect("transition_completed", self, "_on_transition_completed")
	
	if not transition_instance.is_connected("transition_mid_point", self, "_on_transition_mid"):
		transition_instance.connect("transition_mid_point", self, "_on_transition_mid")
	
	# Guardar el destino
	if to_level == 0:
		last_destination = "menu"
	else:
		last_destination = "level"
	
	# Detener música actual para evitar problemas
	if AudioManager:
		AudioManager.stopBGMusic()
	
	# Pausar el juego durante la transición
	scene_tree.paused = true
	
	# Iniciar la transición después de un pequeño retraso para asegurar que todo esté listo
	call_deferred("_start_transition", from_level, to_level)

# Función para iniciar la transición de manera diferida
func _start_transition(from_level, to_level):
	if transition_instance:
		# Iniciar la transición
		transition_instance.start_transition(from_level, to_level)
	
# Función para la transición al menú
func go_to_menu():
	# No ir al menú si ya estamos en él
	if get_tree().current_scene and get_tree().current_scene.name == "LevelSelected":
		print("Ya estamos en el menú, ignorando solicitud")
		return
		
	# Verificar si se permite acceder al menú (no animaciones en curso)
	if Global and !Global.can_access_menu():
		print("No se puede acceder al menú ahora: hay animaciones en curso")
		return
		
	change_level(Global.nivel_actual, 0, false, false)  # Sin números para el menú

# Nueva función para indicar que el nivel está listo
func notify_level_ready():
	level_is_ready = true
	print("Nivel listo para mostrar")
	emit_signal("level_loaded")
	
	# Si estamos esperando en el punto medio de la transición, continuar con fade_out
	if transition_instance and transition_instance.is_animating:
		# Continuar con la transición fade_out
		_continue_transition_after_level_load()
	
# Función para continuar la transición después de que el nivel está cargado
func _continue_transition_after_level_load():
	if transition_instance:
		print("Continuando con fade_out ahora que el nivel está listo")
		# No llamamos directamente a play aquí, porque la transición debe manejar
		# la visibilidad del segundo número primero
	
# Manejador cuando la transición completa la fase de fade-in
func _on_transition_mid():
	# Emitir señal que pueden escuchar otros nodos
	emit_signal("transition_mid_point")
	print("Transición en punto medio")
	
	# Aquí se cambiaría la escena actual
	var to_level = 0
	
	if transition_instance != null:
		to_level = transition_instance.next_level
	
	# Cambiar a la escena del menú si vamos al nivel 0
	if to_level == 0:
		# Si hay una intro sonando, forzar su finalización
		if AudioManager and AudioManager.introPlaying:
			AudioManager.introPlaying = false
		
		var error = get_tree().change_scene("res://Escenas/Gui/LevelSelected.tscn")
		if error != OK:
			print("Error al cambiar a escena LevelSelected: ", error)
		else:
			print("Cambiando a escena LevelSelected")
			
			# Asegurar que Global sepa que estamos en el menú
			if Global:
				Global.set_in_menu(true)
				
		# Para el menú, marcamos que el nivel está listo inmediatamente
		level_is_ready = true
		emit_signal("level_loaded")
	else:
		# Actualizar el nivel actual en Global
		Global.nivel_actual = to_level
		
		# Si no estamos en Main.tscn, cargar esa escena
		if get_tree().current_scene.name != "Main":
			var error = get_tree().change_scene("res://Escenas/Main.tscn")
			if error != OK:
				print("Error al cambiar a escena Main: ", error)
			else:
				print("Cambiando a escena Main para el nivel ", to_level)
				
				# Asegurar que Global sepa que no estamos en el menú
				if Global:
					Global.set_in_menu(false)
				
				# Establecer una bandera para reproducir la música del nivel cuando la escena esté lista
				# Esto lo manejaremos en _on_transition_completed
	
func _on_transition_completed():
	print("Transición completada")
	
	# Limpiar la instancia de transición
	if transition_instance != null:
		transition_instance.queue_free()
		transition_instance = null
	
	# Reanudar el juego basado en el destino
	if last_destination == "menu":
		# Si vamos al menú, asegurarse de que no está pausado
		get_tree().paused = false
		print("Despausando juego en el menú")
		
		# Notificar a AudioManager que la transición terminó
		if AudioManager:
			AudioManager.end_level_transition()
		
		# Y que AudioManager reproduzca la música del menú
		if AudioManager and AudioManager.current_track != AudioManager.TRACKS.MENU:
			AudioManager.startBGMusic(AudioManager.TRACKS.MENU)
	else:
		# Si vamos a un nivel, iniciar música de intro/nivel
		if AudioManager:
			# Notificar a AudioManager que la transición terminó
			AudioManager.end_level_transition()
			
			# Iniciar la música de introducción o la música principal según corresponda
			AudioManager.startBGMusic(AudioManager.TRACKS.INTRO)
			print("Iniciando música de nivel (intro que cambiará a main)")
			
			# Si estamos en un nivel, pero la intro ya ha terminado o no hay intro,
			# reproducir directamente la música principal
			if not AudioManager.introPlaying:
				# Pequeño retraso antes de reproducir la música principal
				yield(get_tree().create_timer(0.2), "timeout")
				AudioManager.startBGMusic(AudioManager.TRACKS.MAIN)
				print("Reproduciendo música principal directamente")
				
				# Pequeño retraso antes de despausar para asegurar que todo esté listo
				get_tree().paused = false
				print("Despausando juego después de transición a nivel")
			else:
				# El juego seguirá pausado hasta que termine la intro
				print("Juego sigue pausado hasta que termine la intro")
		else:
			# Si no hay AudioManager, despausar de todas formas
			get_tree().paused = false
			
	# Finalizar estado de transición
	transition_in_progress = false
	
	# Informar a Global que la animación ha terminado
	if Global:
		Global.set_animation_in_progress(false)
	
	# Emitir señal para que otros scripts sepan que la transición completó
	emit_signal("transition_completed")

# Función para verificar si el nivel está listo
func is_level_ready():
	return level_is_ready
