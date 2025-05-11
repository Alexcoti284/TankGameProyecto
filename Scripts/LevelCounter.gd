extends CanvasLayer

onready var level_label = $Control/LevelLabel
onready var enemies_label = $Control/EnemiesLabel
var initial_enemies_counted = false
var enemy_count = 0

func _ready():

	# Actualizar solo el nivel al iniciar
	update_level_display()
	
	# Establecer un temporizador con un retraso inicial para contar los enemigos correctamente
	var initial_delay = Timer.new()
	initial_delay.wait_time = 0.1  # Medio segundo de retraso antes de contar por primera vez
	initial_delay.one_shot = true
	initial_delay.autostart = true
	initial_delay.connect("timeout", self, "setup_enemy_counter")
	add_child(initial_delay)

func _process(_delta):
	# Actualizar solo el nivel constantemente
	if level_label:
		level_label.text = "LEVEL " + str(Global.nivel_actual)
	
	# El contador de enemigos se actualiza por el timer, no en cada frame

func on_level_start():
	# Reiniciar el contador cuando el nivel inicia
	initial_enemies_counted = false
	update_level_display()
	
	# Vamos a esperar un poco para contar enemigos después del inicio del nivel
	var delay = Timer.new()
	delay.wait_time = 0.1
	delay.one_shot = true
	delay.autostart = true
	delay.connect("timeout", self, "setup_enemy_counter")
	add_child(delay)

func setup_enemy_counter():
	# Contar enemigos una vez que el nivel ha iniciado completamente
	count_enemies()
	
	# Ahora configurar el timer para actualizaciones periódicas
	var update_timer = Timer.new()
	update_timer.name = "EnemyUpdateTimer" # Para poder referenciarlo después
	update_timer.wait_time = 0.1  # Actualizar cada medio segundo
	update_timer.autostart = true
	update_timer.connect("timeout", self, "count_enemies")
	add_child(update_timer)
	
	initial_enemies_counted = true

func update_level_display():
	if level_label:
		level_label.text = "LEVEL " + str(Global.nivel_actual)
	
	# Ya no actualiza el contador de enemigos aquí

func count_enemies():
	# Obtener enemigos sólo de la escena actual
	var current_scene = get_tree().current_scene
	var enemies = []
	
	if current_scene:
		enemies = get_tree().get_nodes_in_group("enemy")
		
		# Verificar que cada enemigo pertenece a la escena actual
		var valid_enemies = []
		for enemy in enemies:
			var scene_root = enemy
			while scene_root.get_parent() and scene_root.get_parent() != get_tree().root:
				scene_root = scene_root.get_parent()
			
			if scene_root == current_scene:
				valid_enemies.append(enemy)
		
		enemy_count = valid_enemies.size()
	else:
		enemy_count = 0
	
	if enemies_label:
		enemies_label.text = "TANKS: " + str(enemy_count)

func _exit_tree():
	# Limpiar timers al eliminar el nodo
	for child in get_children():
		if child is Timer:
			child.stop()
			if child.is_connected("timeout", self, "count_enemies"):
				child.disconnect("timeout", self, "count_enemies")
			if child.is_connected("timeout", self, "setup_enemy_counter"):
				child.disconnect("timeout", self, "setup_enemy_counter")
