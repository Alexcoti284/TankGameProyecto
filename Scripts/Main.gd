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

	# Conectar eventos
	var error = AudioManager.connect("intro_finished", self, "unpause")
	if error != OK:
		print("❌ Error al conectar la señal 'intro_finished': ", error)



	# Si `Global.nivel_actual` está definido, cargar ese nivel
	if Global.nivel_actual > 0:
		currentLevelIndex = Global.nivel_actual - 1 # Ajustar índice (de 1 a 0-indexado)
	else:
		currentLevelIndex = 0 # Si no, empezar desde el primer nivel

	# Cargar el nivel seleccionado o el primer nivel
	nextLevel()

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
	
