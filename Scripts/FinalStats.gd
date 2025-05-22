extends Control

onready var congratulations_label = $CenterContainer/VBoxContainer/CongratulationsLabel
onready var deaths_label = $CenterContainer/VBoxContainer/StatsContainer/DeathsLabel
onready var time_label = $CenterContainer/VBoxContainer/StatsContainer/TimeLabel

onready var menu_button = $CenterContainer/VBoxContainer/ButtonContainer/MenuButton
onready var quit_button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton

# Variables para animaciones
var stats_visible = false
var animation_tween: Tween

func _ready():
	# Informar a Global que estamos en el menú (estadísticas)
	if Global:
		Global.set_in_menu(true)
	
	# Reproducir la música del menú
	if AudioManager and AudioManager.current_track != AudioManager.TRACKS.MENU:
		AudioManager.startBGMusic(AudioManager.TRACKS.MENU)
	
	# Asegurarse de que el juego no está pausado
	if get_tree().paused:
		get_tree().paused = false
		print("Juego despausado en estadísticas finales")
	
	# Asegurarse de que el menú no está bloqueado
	if Global:
		Global.set_menu_blocked(false)
		print("Menú desbloqueado en estadísticas finales")
	
	# Configurar la interfaz inicial
	setup_ui()
	
	# Cargar y mostrar las estadísticas
	load_and_display_stats()
	
	# Animar la aparición de las estadísticas
	animate_stats_appearance()

func _exit_tree():
	# Al salir de las estadísticas, actualizar el estado
	if Global:
		Global.set_in_menu(false)

func setup_ui():
	# Configurar texto inicial
	congratulations_label.text = "¡FELICIDADES!"
	
	# Hacer invisibles las estadísticas inicialmente para animarlas
	var stats_container = $CenterContainer/VBoxContainer/StatsContainer
	var button_container = $CenterContainer/VBoxContainer/ButtonContainer
	
	stats_container.modulate.a = 0.0
	button_container.modulate.a = 0.0
	
	# Conectar botones
	if not menu_button.is_connected("pressed", self, "_on_menu_button_pressed"):
		menu_button.connect("pressed", self, "_on_menu_button_pressed")
	
	if not quit_button.is_connected("pressed", self, "_on_quit_button_pressed"):
		quit_button.connect("pressed", self, "_on_quit_button_pressed")

func load_and_display_stats():
	# Cargar estadísticas desde Global
	var total_deaths = Global.total_deaths
	var total_time = Global.get_total_time()
	
	# Contar niveles completados correctamente
	var levels_completed = 0
	for i in range(Global.niveles_desbloqueados.size()):
		if Global.niveles_desbloqueados[i]:
			levels_completed += 1
	
	# Actualizar las etiquetas con las estadísticas
	deaths_label.text = "Muertes Totales: " + str(total_deaths)
	time_label.text = "Tiempo Total: " + Global.format_time(total_time)

	
	print("Estadísticas finales cargadas:")
	print("- Muertes: ", total_deaths)
	print("- Tiempo: ", Global.format_time(total_time))


func animate_stats_appearance():
	# Crear un Tween para las animaciones
	animation_tween = Tween.new()
	add_child(animation_tween)
	
	var stats_container = $CenterContainer/VBoxContainer/StatsContainer
	var button_container = $CenterContainer/VBoxContainer/ButtonContainer
	
	# Animar la aparición del título (ya está visible)
	var title_scale_tween = Tween.new()
	add_child(title_scale_tween)
	
	congratulations_label.rect_scale = Vector2(0.5, 0.5)
	title_scale_tween.interpolate_property(congratulations_label, "rect_scale",
		Vector2(0.5, 0.5), Vector2(1.0, 1.0), 0.8,
		Tween.TRANS_BACK, Tween.EASE_OUT)
	title_scale_tween.start()
	
	# Esperar un poco y luego mostrar las estadísticas
	yield(get_tree().create_timer(0.5), "timeout")
	
	# Animar aparición de estadísticas
	animation_tween.interpolate_property(stats_container, "modulate:a",
		0.0, 1.0, 0.6, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	animation_tween.start()
	
	# Esperar un poco más y mostrar los botones
	yield(get_tree().create_timer(0.8), "timeout")
	
	animation_tween.interpolate_property(button_container, "modulate:a",
		0.0, 1.0, 0.4, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	animation_tween.start()
	
	# Limpiar los tweens después de las animaciones
	yield(animation_tween, "tween_completed")
	title_scale_tween.queue_free()

func _on_menu_button_pressed():
	print("Botón de menú presionado desde estadísticas finales")
	
	# Reproducir sonido de clic si existe
	if AudioManager and AudioManager.has_method("play"):
		# AudioManager.play(AudioManager.SOUNDS.BUTTON_CLICK)
		pass
	
	# Usar TransitionManager para ir al menú con transición
	TransitionManager.go_to_menu()

func _on_quit_button_pressed():
	print("Botón de salir presionado desde estadísticas finales")
	
	# Guardar datos antes de salir
	if Global:
		Global.guardar_datos()
	
	# Reproducir sonido de clic si existe
	if AudioManager and AudioManager.has_method("play"):
		# AudioManager.play(AudioManager.SOUNDS.BUTTON_CLICK)
		pass
	
	# Salir del juego
	get_tree().quit()

func _input(event):
	# Permitir salir con ESC o la tecla de menú
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		_on_menu_button_pressed()
	elif event.is_action_pressed("quit"):
		_on_quit_button_pressed()
