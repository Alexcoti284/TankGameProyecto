extends Node

signal level_start

var levels = []
var currentLevelIndex = -1
var currentLevel
var transition_in_progress = false
var level_to_load = -1  # Variable para almacenar el nivel que se debe cargar
var level_counter_scene = preload("res://Escenas/Gui/LevelCounter.tscn")
var level_counter_instance

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
	
	# Instanciar y añadir contador de niveles
	level_counter_instance = level_counter_scene.instance()
	add_child(level_counter_instance)
	
	# Conectar con el TransitionManager
	# warning-ignore:return_value_discarded
	if not TransitionManager.is_connected("transition_completed", self, "_on_transition_completed"):
		TransitionManager.connect("transition_completed", self, "_on_transition_completed")
	
	# warning-ignore:return_value_discarded
	if not TransitionManager.is_connected("transition_mid_point", self, "_on_transition_mid_point"):
		TransitionManager.connect("transition_mid_point", self, "_on_transition_mid_point")
	
	# Informar a Global que no estamos en el menú
	if Global:
		Global.set_in_menu(false)

	# IMPORTANTE: Pausar el juego antes de iniciar la música
	get_tree().paused = true
	
	# Asegurar conexión de la señal para despausar cuando termine la intro
	# warning-ignore:return_value_discarded
	if not AudioManager.is_connected("intro_finished", self, "unpause"):
		AudioManager.connect("intro_finished", self, "unpause")
		print("Conectada señal intro_finished a unpause en Main")
	
	# Determinar el índice del nivel actual
	if Global.nivel_actual > 0:
		currentLevelIndex = Global.nivel_actual - 1 # Ajustar índice (de 1 a 0-indexado)
	else:
		currentLevelIndex = 0 # Si no, empezar desde el primer nivel
	
	print("Índice de nivel actual en _ready: ", currentLevelIndex)
	
	# Iniciar la música de introducción al cargar un nivel
	AudioManager.startBGMusic(AudioManager.TRACKS.INTRO)
	
	# Cargar el nivel seleccionado
	call_deferred("_addCurrentLevel")

# Modificar la función nextLevel()
func nextLevel():
	if transition_in_progress:
		print("Transición en progreso, ignorando nextLevel")
		return
	
	transition_in_progress = true
	print("Iniciando nextLevel desde el nivel ", Global.nivel_actual)
	
	currentLevelIndex += 1
	if currentLevelIndex < levels.size():
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
		if level_counter_instance:
			level_counter_instance.update_level_display()
		
		# Usar TransitionManager para la transición con números y animación completa
		print("Transición al siguiente nivel: ", from_level, " -> ", to_level)
		TransitionManager.change_level(from_level, to_level, true, true)
		
	else:
		# Si ya no hay más niveles, volver al menú
		print("No hay más niveles, volviendo al menú")
		TransitionManager.go_to_menu()
	
# Modificar la función restartLevel()
func restartLevel():
	if transition_in_progress:
		print("Transición en progreso, ignorando restartLevel")
		return
	
	transition_in_progress = true
	print("Iniciando restartLevel para el nivel ", Global.nivel_actual)
	
	# Guardar el nivel que se debe cargar después de la transición (el mismo)
	level_to_load = Global.nivel_actual
	
	# Para reiniciar nivel: mostrar números pero SIN animación de cambio
	get_tree().paused = true
	
	# Actualizar el contador de niveles
	if level_counter_instance:
		level_counter_instance.update_level_display()
	
	# Reinicio del mismo nivel: usar false para animate_numbers para una transición más rápida
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

# Nueva función para añadir el nivel y notificar cuando esté listo
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
	
	# Conectar señales del nivel
	# warning-ignore:return_value_discarded
	if not currentLevel.is_connected("enemies_killed", self, 'nextLevel'):
		currentLevel.connect("enemies_killed", self, 'nextLevel')
	
	# warning-ignore:return_value_discarded
	if not currentLevel.is_connected("player_died", self, 'restartLevel'):
		currentLevel.connect("player_died", self, 'restartLevel')
	
	# Añadir el nivel después de conectar las señales
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
	Global.desbloquear_nivel(Global.nivel_actual)
	
	# Actualizar el contador de niveles
	if level_counter_instance:
		level_counter_instance.update_level_display()

# Función para manejar cuando la transición completa
func _on_transition_completed():
	print("Transición completada en Main")
	
	# Permitir nuevas transiciones
	transition_in_progress = false
		
func unpause():
	print("Despausando el juego desde Main")
	if get_tree().paused:
		get_tree().paused = false
		emit_signal("level_start")
