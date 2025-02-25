extends Node
var niveles = []
var IndexActualNivel = -1
var NivelActual


func _ready():
	# coje niveles
	var DirectorioNivel = Directory.new()
	DirectorioNivel.open("res://Escenas/Niveles")
	DirectorioNivel.list_dir_begin(true, true)
	var CadenaFormatNivel = DirectorioNivel.get_current_dir() + "/%s"
	var nivel = DirectorioNivel.get_next() # Coje priimer directorio
	nivel = DirectorioNivel.get_next() # Ignora "Nivel.tscn"

	# Empieza en un nivel (Default es #1)
	for i in Debug.STARTING_LEVEL: nivel = DirectorioNivel.get_next() # Ignora niveles

	while(nivel != ""):
		var CadenaNivel = CadenaFormatNivel % nivel
		var NivelCargado = load(CadenaNivel)
		niveles.append(NivelCargado)
		nivel = DirectorioNivel.get_next()

	# warning-ignore:return_value_discarded
	AudioManager.connect("intro_finished", self, "unpause")
	SiguienteNivel()

func SiguienteNivel():
	IndexActualNivel += 1
	if IndexActualNivel < niveles.size():
		if NivelActual: NivelActual.queue_free()
		get_tree().paused = true
		AudioManager.startMusicaFondo(AudioManager.TRACKS.INTRO)
		_addCurrentLevel()
	else:
		get_tree().quit()

func RestartNivel():
	NivelActual.queue_free()
	get_tree().paused = true
	AudioManager.startMusicaFondo(AudioManager.TRACKS.REPLAY)
	_addCurrentLevel()

func _addCurrentLevel():
	NivelActual = niveles[IndexActualNivel].instance()
	NivelActual.connect("Enemigos_Muertos", self, 'SiguienteNivel')
	NivelActual.connect("Jugador_Muere", self, 'RestartNivel')
	add_child(NivelActual)

func unpause():
	get_tree().paused = false

