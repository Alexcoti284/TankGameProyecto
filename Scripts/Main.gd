extends Node

var levels = []
var currentLevelIndex = -1
var currentLevel

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

	# Asegurar conexión de la señal
	if not AudioManager.is_connected("intro_finished", self, "unpause"):
		AudioManager.connect("intro_finished", self, "unpause")

	# Determinar el índice del nivel actual
	if Global.nivel_actual > 0:
		currentLevelIndex = Global.nivel_actual - 1 # Ajustar índice (de 1 a 0-indexado)
	else:
		currentLevelIndex = 0 # Si no, empezar desde el primer nivel

	# Iniciar la música de introducción solo si es la primera vez
	if Global.nivel_actual == 0:
		print("Reproduciendo intro...")  # DEBUG
		AudioManager.startBGMusic(AudioManager.TRACKS.INTRO)
	else:
		print("Saltando intro, cargando nivel directamente...")  # DEBUG
		unpause()  # Evita que se quede en pausa si no hay intro

	# Cargar el nivel seleccionado o el primer nivel
	_addCurrentLevel()


func nextLevel():
	currentLevelIndex += 1
	if currentLevelIndex < levels.size():
		if currentLevel: currentLevel.queue_free()
		get_tree().paused = true
		AudioManager.startBGMusic(AudioManager.TRACKS.INTRO)
		_addCurrentLevel()
	else:
		get_tree().quit()

func restartLevel():
	currentLevel.queue_free()
	get_tree().paused = true
	AudioManager.startBGMusic(AudioManager.TRACKS.REPLAY)
	_addCurrentLevel()

func _addCurrentLevel():

	currentLevel = levels[currentLevelIndex].instance()
	currentLevel.connect("enemies_killed", self, 'nextLevel')
	currentLevel.connect("player_died", self, 'restartLevel')
	add_child(currentLevel)


func unpause():
	print("Despausando el juego")
	get_tree().paused = false
	emit_signal("level_start")
	
