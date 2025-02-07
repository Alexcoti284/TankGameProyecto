extends TileMap
const BloqueDestructible = preload("res://Escenas/BloqueDestructible.tscn")

signal Jugador_Muere
signal enemies_killed
signal level_start
signal level_end

# Entra directamente la primera vez
func _ready():
	var enemies = get_tree().get_nodes_in_group("Enemigo")
	for e in enemies:
		e.connect("killed", self, "checkIfAllEnemiesKilled") 
	
	var EnemigosInvis = get_tree().get_nodes_in_group("invisible")
	for e in EnemigosInvis:
		# warning-ignore:return_value_discarded
		self.connect("level_start", e, "fade_in")
		# warning-ignore:return_value_discarded
		self.connect("level_end", e, "fade_out")
	
	emit_signal("level_start")

	# Remplaza los tiles por los tiles del bloque
	var Destruct_HMid = get_used_cells_by_id(33) # 23 is the index for straw horizontal
	for Bloque in Destruct_HMid:
		set_cellv(Bloque,-1)
		var EscenaBloqueDestructible = BloqueDestructible.instance()
		EscenaBloqueDestructible.position = Bloque*16 + Vector2(8,8)
		EscenaBloqueDestructible.vertical = false
		add_child(EscenaBloqueDestructible)
	var Destruct_HIzq = get_used_cells_by_id(36) # 24 is the index for straw vertical
	for Bloque in Destruct_HIzq:
		set_cellv(Bloque,-1)
		var EscenaBloqueDestructible = BloqueDestructible.instance()
		EscenaBloqueDestructible.position = Bloque*16 + Vector2(8,8)
		EscenaBloqueDestructible.vertical = true
		add_child(EscenaBloqueDestructible)
		
	var Destruct_HDer = get_used_cells_by_id(34) # 24 is the index for straw vertical
	for Bloque in Destruct_HDer:
		set_cellv(Bloque,-1)
		var EscenaBloqueDestructible = BloqueDestructible.instance()
		EscenaBloqueDestructible.position = Bloque*16 + Vector2(8,8)
		EscenaBloqueDestructible.vertical = true
		add_child(EscenaBloqueDestructible)
		
	var Destruct_V = get_used_cells_by_id(32) # 24 is the index for straw vertical
	for Bloque in Destruct_V:
		set_cellv(Bloque,-1)
		var EscenaBloqueDestructible = BloqueDestructible.instance()
		EscenaBloqueDestructible.position = Bloque*16 + Vector2(8,8)
		EscenaBloqueDestructible.vertical = true
		add_child(EscenaBloqueDestructible)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if (get_node_or_null("TanquePlayer")):
		var tankDirection
		if (Input.is_action_pressed("move_up") && Input.is_action_pressed("move_right")):
			tankDirection = $TanquePlayer.directions.UP_RIGHT
		elif (Input.is_action_pressed("move_down") && Input.is_action_pressed("move_left")):
			tankDirection = $TanquePlayer.directions.DOWN_LEFT
		elif (Input.is_action_pressed("move_up") && Input.is_action_pressed("move_left")):
			tankDirection = $TanquePlayer.directions.UP_LEFT
		elif Input.is_action_pressed("move_down") && Input.is_action_pressed("move_right"):
			tankDirection = $TanquePlayer.directions.DOWN_RIGHT
		elif Input.is_action_pressed("move_up") :
			tankDirection = $TanquePlayer.directions.UP
		elif Input.is_action_pressed("move_down"):
			tankDirection = $TanquePlayer.directions.DOWN
		elif Input.is_action_pressed("move_left"):
			tankDirection = $TanquePlayer.directions.LEFT
		elif Input.is_action_pressed("move_right"):
			tankDirection = $TanquePlayer.directions.RIGHT

		if tankDirection:
			if (!$TanquePlayer/SonidoMovimiento.playing):
				$TanquePlayer/SonidoMovimiento.playing = true
			$TanquePlayer.mover(delta, tankDirection)
		else:
			$TanquePlayer/SonidoMovimiento.playing = false
			
		if Input.is_action_just_pressed("disparar"):
			$TanquePlayer.tryToShoot()
			
		if Input.is_action_just_pressed("mina"):
			$TanquePlayer.tryToPlantMine()

func checkIfAllEnemiesKilled():
	var enemies = get_tree().get_nodes_in_group("Enemigo").size()
	if (enemies == 0):
		if (get_parent().name == "Main"):
			deleteAllBullets()
			var nextLevel_timer = Timer.new()
			nextLevel_timer.wait_time = 2
			nextLevel_timer.autostart = true
			nextLevel_timer.connect("timeout", self, "_on_nextLevel_timer_timeout") 
			call_deferred("add_child", nextLevel_timer)
			AudioManager.startBGMusic(AudioManager.TRACKS.WIN)
		else:
			get_tree().quit()
	else:
		AudioManager.play(AudioManager.SOUNDS.TANK_KILL)

func _on_nextLevel_timer_timeout():
	if (get_parent().name == "Main"):
		emit_signal("enemies_killed")
	else:
		get_tree().quit()

func _on_TanquePlayer_Jugador_Muere():
	deleteAllBullets()

	var death_timer = Timer.new()
	death_timer.wait_time = 2
	death_timer.autostart = true
	death_timer.connect("timeout", self, "_on_death_timer_timeout") 
	add_child(death_timer)
	
	AudioManager.startBGMusic(AudioManager.TRACKS.LOSE)
	emit_signal("level_end")


func _on_death_timer_timeout():
	if (get_parent().name == "Main"):
		emit_signal("Jugador_Muere")
	else:
		get_tree().quit()

func deleteAllBullets():
	for node in get_children():
		if(node is Bala): 
			node.instanceSmoke(false)
			node.queue_free()



