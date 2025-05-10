extends Node

var num_players = 8
var available = []  # The available players.
var queue = []  # The queue of sounds to play.
var introPlaying = false
var outroPlaying = false
var current_track = -1 # Para recordar qué pista estaba sonando
var level_transition_in_progress = false # Nueva variable para controlar transiciones de nivel

signal intro_finished


enum SOUNDS {
	SMOKE,
	SHOT,
	BOUNCE,
	TANK_MOVE,
	MINE,
	BLAST,
	TANK_DEATH,
	BULLET_SHOT,
	MINE_CANT,
	TANK_KILL
}

enum TRACKS {
	WIN,
	LOSE,
	INTRO,
	MAIN,
	REPLAY,
	MENU,
}

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS  # Asegurar que el audio siga incluso en pausa
	
	# Crear el BGMusic como un hijo de este nodo si no existe
	if not has_node("BGMusic"):
		var bg_music = AudioStreamPlayer.new()
		bg_music.name = "BGMusic"
		bg_music.bus = "master"
		add_child(bg_music)
		bg_music.connect("finished", self, "_on_BGMusic_finished")
	
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.connect("finished", self, "_on_stream_finished", [p])
		p.bus = "master"

func _on_stream_finished(stream):
	# When finished playing a stream, make the player available again.
	available.append(stream)

func play(sound):
	queue.append(sound)

func startBGMusic(track):
	# Si hay una transición en progreso y no es el menú, no iniciar nueva música
	if level_transition_in_progress and track != TRACKS.MENU:
		print("Transición en progreso, posponiendo música: ", track)
		return
		
	# Si la pista que se quiere reproducir ya está sonando, no hacer nada
	if current_track == track and $BGMusic.playing and not $BGMusic.stream_paused:
		print("Ya está sonando la pista: ", track)
		return
		
	# Si hay una pista diferente sonando, detenerla primero
	if $BGMusic.playing or $BGMusic.stream_paused:
		$BGMusic.stop()
		print("Deteniendo pista anterior antes de iniciar nueva")
		
	current_track = track # Guardar la pista actual
	
	match(track):
		TRACKS.INTRO:
			$BGMusic.stream = preload("res://SFX/intro.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = true
			outroPlaying = false
			# Bloquear el menú mientras suena la intro
			if Global:
				Global.set_menu_blocked(true)
				print("Menú bloqueado por intro")
		TRACKS.MAIN:
			$BGMusic.stream = preload("res://SFX/main.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = false
			outroPlaying = false
			print("Reproduciendo música principal del nivel")
		TRACKS.WIN:
			if ($BGMusic.stream != preload("res://SFX/lose.wav")):
				$BGMusic.stream = preload("res://SFX/win.wav")
				$BGMusic.volume_db = -5
				$BGMusic.play()
				outroPlaying = true
				introPlaying = false
				# Bloquear menú durante la música de victoria
				if Global:
					Global.set_menu_blocked(true)
					print("Menú bloqueado por música de victoria")
		TRACKS.LOSE:
			if ($BGMusic.stream != preload("res://SFX/win.wav")):
				$BGMusic.stream = preload("res://SFX/lose.wav")
				$BGMusic.volume_db = -5
				$BGMusic.play()
				outroPlaying = true
				introPlaying = false
				# Bloquear menú durante la música de derrota
				if Global:
					Global.set_menu_blocked(true)
					print("Menú bloqueado por música de derrota")
		TRACKS.REPLAY:
			$BGMusic.stream = preload("res://SFX/replay.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = true
			outroPlaying = false
			# Bloquear el menú mientras suena la intro
			if Global:
				Global.set_menu_blocked(true)
				print("Menú bloqueado por replay")
		TRACKS.MENU:
			$BGMusic.stream = preload("res://SFX/MusicaMenu.wav")
			$BGMusic.volume_db = -5
			$BGMusic.play()
			introPlaying = false
			outroPlaying = false
			print("Reproduciendo música de menú")

func _process(_delta):
	# Play a queued sound if any players are available.
	if not queue.empty() and not available.empty():
		var sound = queue.pop_front()
		var player = available.pop_front()
		
		match(sound):
			SOUNDS.SMOKE:
				player.stream = preload("res://SFX/smoke.wav")
				player.volume_db = -15
			SOUNDS.SHOT:
				player.stream = preload("res://SFX/shot.wav")
				player.volume_db = -10
			SOUNDS.BOUNCE:
				player.stream = preload("res://SFX/bounce.wav")
				player.volume_db = -2
			SOUNDS.TANK_MOVE:
				player.stream = preload("res://SFX/tank_move.wav")
				player.volume_db = -10
			SOUNDS.MINE:
				player.stream = preload("res://SFX/mine.wav")
				player.volume_db = -10
			SOUNDS.BLAST:
				player.stream = preload("res://SFX/bomb.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.TANK_DEATH:
				player.stream = preload("res://SFX/tank_death.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.BULLET_SHOT:
				player.stream = preload("res://SFX/bullet_shot.wav")
				player.stream.loop_mode = 0
				player.volume_db = -15
			SOUNDS.MINE_CANT:
				player.stream = preload("res://SFX/mine_cant.wav")
				player.stream.loop_mode = 0
				player.volume_db = -5
			SOUNDS.TANK_KILL:
				player.stream = preload("res://SFX/tank_kill.wav")
				player.stream.loop_mode = 0
				player.volume_db = -6
		
		player.play()

func _on_BGMusic_finished():
	print("BGMusic terminada. introPlaying =", introPlaying)
	if introPlaying:
		introPlaying = false
		# Desbloquear el menú explícitamente
		if Global:
			Global.set_menu_blocked(false)
		emit_signal("intro_finished")
		# Solo reproducir música principal si no estamos en el menú y no hay transición en progreso
		if not Global.in_menu and not level_transition_in_progress:
			startBGMusic(TRACKS.MAIN)
			print("Cambiando a música principal después de intro")
			
			# Despausar el juego después de la intro
			if get_tree().paused:
				get_tree().paused = false
				print("Despausando juego después de intro")
	elif outroPlaying:
		outroPlaying = false
		# Desbloquear el menú después de la música de victoria/derrota
		if Global:
			Global.set_menu_blocked(false)
	else:
		# Si no es intro ni outro, y no estamos en el menú o transición, reiniciar música normal
		if not Global.in_menu and current_track != TRACKS.MENU and not level_transition_in_progress:
			startBGMusic(TRACKS.MAIN)
			print("Reiniciando música principal")

func pauseBGMusic():
	if $BGMusic.playing:
		$BGMusic.stream_paused = true
		print("Música pausada")

func resumeBGMusic():
	if $BGMusic.stream_paused:
		$BGMusic.stream_paused = false
		print("Música reanudada")
		
func stopBGMusic():
	if $BGMusic.playing or $BGMusic.stream_paused:
		$BGMusic.stop()
		print("Música detenida completamente")
		
# Nuevo método para asegurar que la música del nivel esté sonando
func ensureLevelMusic():
	# Si estamos en un nivel pero no hay música sonando o está pausada
	if not Global.in_menu and (not $BGMusic.playing or $BGMusic.stream_paused):
		# Si la intro no está sonando y no estamos reproduciendo la música principal,
		# iniciar la música principal
		if not introPlaying and current_track != TRACKS.MAIN and not level_transition_in_progress:
			startBGMusic(TRACKS.MAIN)
			print("Asegurando que la música del nivel está sonando")

# Nuevos métodos para controlar transiciones de nivel
func start_level_transition():
	level_transition_in_progress = true
	print("Iniciando transición de nivel en AudioManager")
	
func end_level_transition():
	level_transition_in_progress = false
	print("Finalizando transición de nivel en AudioManager")
	
	# Si estamos en un nivel, asegurar que suene la música adecuada
	if not Global.in_menu:
		if current_track != TRACKS.INTRO and current_track != TRACKS.MAIN:
			startBGMusic(TRACKS.INTRO)
	else:
		# Si estamos en menú, asegurar que suene la música de menú
		if current_track != TRACKS.MENU:
			startBGMusic(TRACKS.MENU)
