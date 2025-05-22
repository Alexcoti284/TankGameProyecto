extends TileMap
const Straw = preload("res://Escenas/Straw.tscn")

signal player_died
signal enemies_killed
signal level_start
signal level_end


# Variables para control de transición
var victory_in_progress = false
var death_in_progress = false
var start_text_label = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Global.desbloquear_todos_niveles(45)
	print("Ejecutando _ready() en Level.gd")
	
	var scene_name = get_parent().name # Obtiene el nombre de la escena
	print("Nombre de la escena: ", scene_name)
	
	# Extraer el número del formato Level001, Level002, etc.
	var level_str = scene_name.replace("Level", "")
	var level_number = level_str.to_int()
	print("Número de nivel extraído: ", level_number)
	
	# Solo establecer el nivel actual si es un nivel válido
	if level_number > 0:
		Global.nivel_actual = level_number # Guarda el nivel actual en Global
		print("Nivel actual establecido: ", Global.nivel_actual)
	else:
		print("No se pudo extraer un número de nivel válido")
	
	# Reiniciar el tiempo del nivel cuando se carga
	Global.reset_level_time()
	
	# Conectar con enemigos
	var enemies = get_tree().get_nodes_in_group("enemy")
	print("Cantidad de enemigos encontrados: ", enemies.size())
	for e in enemies:
		# warning-ignore:return_value_discarded
		if not e.is_connected("killed", self, "checkIfAllEnemiesKilled"):
			e.connect("killed", self, "checkIfAllEnemiesKilled")
			print("Conectado enemigo a la señal 'killed'")
	
	var invisibleEnemies = get_tree().get_nodes_in_group("invisible")
	print("Cantidad de enemigos invisibles encontrados: ", invisibleEnemies.size())
	for e in invisibleEnemies:
		# warning-ignore:return_value_discarded
		if not self.is_connected("level_start", e, "fade_in"):
			self.connect("level_start", e, "fade_in")
		# warning-ignore:return_value_discarded
		if not self.is_connected("level_end", e, "fade_out"):
			self.connect("level_end", e, "fade_out")
	
	print("Emitiendo señal level_start")
	emit_signal("level_start")
	
	# Asegúrate de que el menú no está bloqueado al inicio de un nivel regular
	# Solo si hay una intro o replay, AudioManager bloqueará el menú
	if get_parent() and get_parent().name == "Main" and not AudioManager.introPlaying:
		Global.set_menu_blocked(false)
		print("Menú desbloqueado en _ready de Level")
		
	# Asegurar que la música del nivel esté sonando si no hay intro
	if get_parent() and get_parent().name == "Main" and not AudioManager.introPlaying:
		# Pequeño retraso para asegurar que la escena esté completamente cargada

		AudioManager.ensureLevelMusic()

	# Replace straw tiles with straw scenes
	var straws_h = get_used_cells_by_id(33) # 33 is the index for straw horizontal
	print("Cantidad de paja horizontal encontrada: ", straws_h.size())
	for straw in straws_h:
		set_cellv(straw,-1)
		var sceneStraw = Straw.instance()
		sceneStraw.position = straw*16 + Vector2(8,8)
		sceneStraw.vertical = false
		add_child(sceneStraw)
		
	var straws_v = get_used_cells_by_id(32) # 32 is the index for straw vertical
	print("Cantidad de paja vertical encontrada: ", straws_v.size())
	for straw in straws_v:
		set_cellv(straw,-1)
		var sceneStraw = Straw.instance()
		sceneStraw.position = straw*16 + Vector2(8,8)
		sceneStraw.vertical = true
		add_child(sceneStraw)
	
	print("_ready() en Level.gd completado")
	
	# Notificar a TransitionManager que el nivel está listo
	if TransitionManager:
		TransitionManager.notify_level_ready()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (get_node_or_null("PlayerTank")):        
		var tankDirection
		if (Input.is_action_pressed("move_up") && Input.is_action_pressed("move_right")):
			tankDirection = $PlayerTank.directions.UP_RIGHT
		elif (Input.is_action_pressed("move_down") && Input.is_action_pressed("move_left")):
			tankDirection = $PlayerTank.directions.DOWN_LEFT
		elif (Input.is_action_pressed("move_up") && Input.is_action_pressed("move_left")):
			tankDirection = $PlayerTank.directions.UP_LEFT
		elif Input.is_action_pressed("move_down") && Input.is_action_pressed("move_right"):
			tankDirection = $PlayerTank.directions.DOWN_RIGHT
		elif Input.is_action_pressed("move_up") :
			tankDirection = $PlayerTank.directions.UP
		elif Input.is_action_pressed("move_down"):
			tankDirection = $PlayerTank.directions.DOWN
		elif Input.is_action_pressed("move_left"):
			tankDirection = $PlayerTank.directions.LEFT
		elif Input.is_action_pressed("move_right"):
			tankDirection = $PlayerTank.directions.RIGHT

		if tankDirection:
			if (!$PlayerTank/MovingSound.playing):
				$PlayerTank/MovingSound.playing = true
			$PlayerTank.move(delta, tankDirection)
		else:
			$PlayerTank/MovingSound.playing = false
			
		if Input.is_action_just_pressed("shoot"):
			$PlayerTank.tryToShoot()
			
		if Input.is_action_just_pressed("plant_mine"):
			$PlayerTank.tryToPlantMine()
func checkIfAllEnemiesKilled():
	# Evitar múltiples ejecuciones
	if victory_in_progress:
		return
		
	var enemies = get_tree().get_nodes_in_group("enemy").size()
	print("Enemigos restantes después de eliminar uno: ", enemies)
	if enemies == 0:
		victory_in_progress = true
		print("Todos los enemigos eliminados en nivel ", Global.nivel_actual)
		deleteAllBullets()
		
		# Emitir señal de fin de nivel antes de cualquier música o transición
		print("Emitiendo señal level_end")
		emit_signal("level_end")
		
		if get_parent() and get_parent().name == "Main":
			var next_level = Global.nivel_actual + 1
			print("Intentando desbloquear nivel: ", next_level)
			Global.desbloquear_nivel(next_level)
			
			# Notificar a AudioManager que comenzamos una transición de nivel
			if AudioManager:
				# Detener cualquier música previa antes de reproducir la de victoria
				AudioManager.stopBGMusic()
				
				# Reproducir música de victoria
				AudioManager.startBGMusic(AudioManager.TRACKS.WIN)
				# Bloquear el menú mientras suena la música de victoria
				Global.set_menu_blocked(true)
			
			# Iniciamos un temporizador corto y luego emitimos la señal para Main
			var nextLevel_timer = Timer.new()
			nextLevel_timer.wait_time = 2
			nextLevel_timer.one_shot = true
			nextLevel_timer.autostart = true
			# warning-ignore:return_value_discarded
			nextLevel_timer.connect("timeout", self, "_on_nextLevel_timer_timeout") 
			call_deferred("add_child", nextLevel_timer)
		else:
			get_tree().quit()
	else:
		AudioManager.play(AudioManager.SOUNDS.TANK_KILL)

func _on_PlayerTank_player_dies():
	# Evitar múltiples ejecuciones
	if death_in_progress:
		return
		
	death_in_progress = true
	deleteAllBullets()

	# Incrementar contador de muertes en Global
	Global.increment_deaths()

	# Emitir señal de fin de nivel antes de cualquier música o transición
	print("Emitiendo señal level_end (player_dies)")
	emit_signal("level_end")
	
	# Notificar a AudioManager que comenzamos una transición de nivel
	if AudioManager:
		# Detener cualquier música previa antes de reproducir la de derrota
		AudioManager.stopBGMusic()
		
		# Reproducir música de derrota
		AudioManager.startBGMusic(AudioManager.TRACKS.LOSE)
		
		# Bloquear el menú mientras suena la música de derrota
		Global.set_menu_blocked(true)
	
	# Esperar un poco antes de emitir player_died para dar tiempo a la música
	var death_timer = Timer.new()
	death_timer.wait_time = 1.0  # Reducido de 2.0 a 1.0 segundos
	death_timer.one_shot = true
	death_timer.autostart = true
	# warning-ignore:return_value_discarded
	death_timer.connect("timeout", self, "_on_death_timer_timeout") 
	add_child(death_timer)

func _on_nextLevel_timer_timeout():
	if is_instance_valid(self) and is_inside_tree() and get_parent() and get_parent().name == "Main":
		emit_signal("enemies_killed")
	else:
		# Si no estamos en el árbol de escenas o el padre ya no es válido
		if OS.has_feature("standalone"):
			get_tree().quit()

	
func _on_death_timer_timeout():
	if is_instance_valid(self) and is_inside_tree() and get_parent() and get_parent().name == "Main":
		emit_signal("player_died")
	else:
		# Si no estamos en el árbol de escenas o el padre ya no es válido
		if OS.has_feature("standalone"):
			get_tree().quit()

func deleteAllBullets():
	for node in get_children():
		if(node is Bullet): 
			node.instanceSmoke(false)
			node.queue_free()

# Called when this node is about to be removed from the scene tree
func _exit_tree():
	# Limpiar temporizadores creados dinámicamente para evitar errores de referencias
	for child in get_children():
		if child is Timer:
			child.stop()
			if child.is_connected("timeout", self, "_on_nextLevel_timer_timeout"):
				child.disconnect("timeout", self, "_on_nextLevel_timer_timeout")
			if child.is_connected("timeout", self, "_on_death_timer_timeout"):
				child.disconnect("timeout", self, "_on_death_timer_timeout")
