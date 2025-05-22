extends Node

signal level_start

var levels = []
var currentLevelIndex = -1
var currentLevel
var transition_in_progress = false
var level_to_load = -1  # Variable para almacenar el nivel que se debe cargar
var level_counter_scene = preload("res://Escenas/Gui/LevelCounter.tscn")
var level_counter_instance
var final_stats_requested = false  # Nueva variable para controlar el flujo a estadísticas

# Constante para el número máximo de niveles
const MAX_LEVELS = 45

func _ready():
	# Obtener niveles
	var levelsdir = Directory.new()
	levelsdir.open("res://Escenas/Niveles")
	levelsdir.list_dir_begin(true, true)
	var levelStringFormat = levelsdir.get_current_dir() + "/%s"
	var level = levelsdir.get_next() # Obtener primer archivo
	level = levelsdir.get_next() # Ignorar "Level.tscn"
	
	# Obtener lista de niveles
	while(level != ""):
		var levelString = levelStringFormat % level
		var loadedLevel = load(levelString)
		levels.append(loadedLevel)
		level = levelsdir.get_next()
	
	print("Niveles cargados: ", levels.size())
	
	# Instanciar y añadir contador de niveles
	if level_counter_scene:
		level_counter_instance = level_counter_scene.instance()
		add_child(level_counter_instance)
	
	# Conectar con el TransitionManager - CON VERIFICACIÓN
	if TransitionManager and not TransitionManager.is_connected("transition_completed", self, "_on_transition_completed"):
		var _unused = TransitionManager.connect("transition_completed", self, "_on_transition_completed")
	
	if TransitionManager and not TransitionManager.is_connected("transition_mid_point", self, "_on_transition_mid_point"):
		var _unused2 = TransitionManager.connect("transition_mid_point", self, "_on_transition_mid_point")
	
	# Informar a Global que no estamos en el menú
	if Global:
		Global.set_in_menu(false)

	# IMPORTANTE: Pausar el juego antes de iniciar la música
	get_tree().paused = true
	
	# Asegurar conexión de la señal para despausar cuando termine la intro - CON VERIFICACIÓN
	if AudioManager and not AudioManager.is_connected("intro_finished", self, "unpause"):
		var _unused3 = AudioManager.connect("intro_finished", self, "unpause")
		print("Conectada señal intro_finished a unpause en Main")
	
	# Determinar el índice del nivel actual
	if Global.nivel_actual > 0:
		currentLevelIndex = Global.nivel_actual - 1 # Ajustar índice (de 1 a 0-indexado)
	else:
		currentLevelIndex = 0 # Si no, empezar desde el primer nivel
	
	print("Índice de nivel actual en _ready: ", currentLevelIndex)
	
	# Iniciar la música de introducción al cargar un nivel
	if AudioManager:
		AudioManager.startBGMusic(AudioManager.TRACKS.INTRO)
	
	# Cargar el nivel seleccionado
	call_deferred("_addCurrentLevel")

func nextLevel():
	if transition_in_progress:
		print("Transición en progreso, ignorando nextLevel")
		return
	
	print("Iniciando nextLevel desde el nivel ", Global.nivel_actual)
	
	# Verificar si hemos completado todos los niveles
	if Global.nivel_actual >= MAX_LEVELS:
		print("¡Todos los niveles completados! Iniciando transición a estadísticas finales")
		start_final_stats_transition()
		return
	
	# Verificar si hay más niveles en el array
	if currentLevelIndex + 1 >= levels.size():
		print("No hay más niveles en el array. Iniciando transición a estadísticas finales")
		start_final_stats_transition()
		return
	
	# Solo establecer transition_in_progress si vamos a continuar con niveles normales
	transition_in_progress = true
	
	currentLevelIndex += 1
	
	# Iniciar transición CON animación para avanzar al siguiente nivel
	get_tree().paused = true
	var from_level = Global.nivel_actual
	var to_level = currentLevelIndex + 1
	
	# Guardar el nivel que se debe cargar después de la transición
	level_to_load = to_level
	
	# Actualizar el nivel actual en Global
	Global.nivel_actual = to_level
	
	# Desbloquear el nivel en Global
	Global.desbloquear_nivel(to_level)
	
	# Actualizar el contador de niveles
	if level_counter_instance and level_counter_instance.has_method("update_level_display"):
		level_counter_instance.update_level_display()
	
	print("Transición al siguiente nivel: ", from_level, " -> ", to_level)
	if TransitionManager:
		TransitionManager.change_level(from_level, to_level, true, true)

func start_final_stats_transition():
	# Evitar múltiples llamadas
	if final_stats_requested or transition_in_progress:
		print("Transición a estadísticas ya solicitada o en progreso, ignorando")
		return
	
	final_stats_requested = true
	transition_in_progress = true
	
	print("Iniciando transición a estadísticas finales desde nivel ", Global.nivel_actual)
	
	# Preparar y guardar las estadísticas finales antes de la transición
	prepare_final_stats()
	
	# Detener cualquier música actual y reproducir música de victoria
	if AudioManager:
		AudioManager.stopBGMusic()
		AudioManager.startBGMusic(AudioManager.TRACKS.WIN)
		# Bloquear el menú temporalmente mientras suena la música de victoria
		if Global:
			Global.set_menu_blocked(true)
	
	# Pausar el juego para la transición
	get_tree().paused = true
	
	# Esperar un poco para que se escuche la música de victoria, luego iniciar transición
	var victory_timer = Timer.new()
	victory_timer.wait_time = 2.0  # 2 segundos de música de victoria
	victory_timer.one_shot = true
	victory_timer.autostart = true
	var _unused = victory_timer.connect("timeout", self, "_start_stats_transition")
	add_child(victory_timer)

func prepare_final_stats():
	# Asegurar que las estadísticas finales están actualizadas
	if Global:
		# Actualizar el tiempo total actual antes de mostrar las estadísticas
		var current_session_time = (OS.get_ticks_msec() / 1000.0) - Global.session_start_time
		Global.total_time += current_session_time
		Global.session_start_time = OS.get_ticks_msec() / 1000.0  # Reiniciar para evitar contar doble
		
		# Guardar todos los datos finales
		Global.guardar_datos()
		
		print("Estadísticas finales preparadas:")
		print("- Tiempo total: ", Global.format_time(Global.total_time))
		print("- Muertes totales: ", Global.total_deaths)
		print("- Niveles completados: ", Global.niveles_desbloqueados.size())

func _start_stats_transition():
	# Desbloquear el menú
	if Global:
		Global.set_menu_blocked(false)
	
	# Iniciar la transición a las estadísticas finales usando TransitionManager
	if TransitionManager:
		print("Iniciando transición visual a estadísticas finales")
		TransitionManager.go_to_final_stats()
	else:
		# Fallback si no hay TransitionManager
		print("No hay TransitionManager, yendo directo a estadísticas")
		var error = get_tree().change_scene("res://Escenas/Gui/FinalStats.tscn")
		if error != OK:
			print("Error al cambiar a FinalStats: ", error)

func restartLevel():
	if transition_in_progress:
		print("Transición en progreso, ignorando restartLevel")
		return
	
	# No permitir reinicio si ya se solicitaron las estadísticas finales
	if final_stats_requested:
		print("Estadísticas finales ya solicitadas, ignorando restartLevel")
		return
	
	transition_in_progress = true
	print("Iniciando restartLevel para el nivel ", Global.nivel_actual)
	
	# Guardar el nivel que se debe cargar después de la transición (el mismo)
	level_to_load = Global.nivel_actual
	
	# Para reiniciar nivel: mostrar números pero SIN animación de cambio
	get_tree().paused = true
	
	# Actualizar el contador de niveles
	if level_counter_instance and level_counter_instance.has_method("update_level_display"):
		level_counter_instance.update_level_display()
	
	# Reinicio del mismo nivel: usar false para animate_numbers para una transición más rápida
	if TransitionManager:
		TransitionManager.change_level(Global.nivel_actual, Global.nivel_actual, true, false)

func _on_transition_mid_point():
	print("Punto medio de transición en Main, preparando para recrear el nivel")
	
	# Eliminar el nivel actual si existe
	if currentLevel:
		if currentLevel.is_connected("enemies_killed", self, 'nextLevel'):
			currentLevel.disconnect("enemies_killed", self, 'nextLevel')
		if currentLevel.is_connected("player_died", self, 'restartLevel'):
			currentLevel.disconnect("player_died", self, 'restartLevel')
		currentLevel.queue_free()
		currentLevel = null
	
	# Ahora creamos el nivel inmediatamente en el punto medio
	# y notificamos cuando esté listo
	call_deferred("_addCurrentLevelAndNotify")

func _addCurrentLevelAndNotify():
	_addCurrentLevel()

	# Notificar al TransitionManager que el nivel está listo
	if TransitionManager:
		TransitionManager.notify_level_ready()
		print("Nivel creado y listo para mostrar, notificando a TransitionManager")

func _addCurrentLevel():
	# Verificar límites del índice
	if currentLevelIndex < 0 or currentLevelIndex >= levels.size():
		print("Índice de nivel inválido: ", currentLevelIndex)
		return
	
	# Si hay un nivel actual, eliminarlo (aunque debería estar ya eliminado)
	if currentLevel:
		if currentLevel.is_connected("enemies_killed", self, 'nextLevel'):
			currentLevel.disconnect("enemies_killed", self, 'nextLevel')
		if currentLevel.is_connected("player_died", self, 'restartLevel'):
			currentLevel.disconnect("player_died", self, 'restartLevel')
		currentLevel.queue_free()
	
	# Instanciar un nivel NUEVO
	print("Instanciando nivel: ", currentLevelIndex)
	currentLevel = levels[currentLevelIndex].instance()
	
	# Conectar señales del nivel - CON VERIFICACIÓN
	if currentLevel and not currentLevel.is_connected("enemies_killed", self, 'nextLevel'):
		var _unused5 = currentLevel.connect("enemies_killed", self, 'nextLevel')
	
	if currentLevel and not currentLevel.is_connected("player_died", self, 'restartLevel'):
		var _unused6 = currentLevel.connect("player_died", self, 'restartLevel')
	
	# Añadir el nivel después de conectar las señales
	if currentLevel:
		add_child(currentLevel)
		print("Nivel añadido como hijo de Main")
	
	# Asegurarse de que nivel_actual se actualice correctamente
	print("Nivel antes de actualizar: ", Global.nivel_actual)
	print("Índice del nivel actual: ", currentLevelIndex)
	
	# Si estamos cargando desde el selector, Global.nivel_actual ya debería ser correcto
	# Si estamos pasando al siguiente nivel, actualizar Global.nivel_actual
	if currentLevelIndex + 1 != Global.nivel_actual:
		Global.nivel_actual = currentLevelIndex + 1
		print("Nivel actualizado a: ", Global.nivel_actual)
	
	# Desbloquear el nivel actual en Global
	if Global:
		Global.desbloquear_nivel(Global.nivel_actual)
	
	# Actualizar el contador de niveles
	if level_counter_instance:
		if level_counter_instance.has_method("update_level_display"):
			level_counter_instance.update_level_display()
		# Notificar al contador que el nivel ha iniciado
		if level_counter_instance.has_method("on_level_start"):
			level_counter_instance.on_level_start()

func _on_transition_completed():
	print("Transición completada en Main")
	
	# Permitir nuevas transiciones
	transition_in_progress = false
	
	# Si se completó una transición a estadísticas finales, ya no necesitamos hacer nada más
	if final_stats_requested:
		print("Transición a estadísticas finales completada")
		
func unpause():
	print("Despausando el juego desde Main")
	if get_tree().paused:
		get_tree().paused = false
		emit_signal("level_start")

# Función para resetear el estado (útil para debugging o reiniciar el juego)
func reset_game_state():
	final_stats_requested = false
	transition_in_progress = false
	print("Estado del juego reseteado")
