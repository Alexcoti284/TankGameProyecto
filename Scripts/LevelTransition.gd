extends CanvasLayer

signal transition_completed
signal transition_mid_point

# Configuraciones de la animación
export var show_numbers = true
export var animate_numbers = true
export var transition_time = 1.0
export var number_animation_time = 0.5
export var delay_before_fade_out = 0.5
export var next_number_display_time = 1.0  # Tiempo que se muestra el segundo número

# Nuevas variables para tiempos reducidos en reinicio de nivel
export var restart_transition_time = 0.5  # Tiempo reducido para reinicio del mismo nivel
export var restart_number_display_time = 0.3  # Tiempo reducido para mostrar números en reinicio

# Variables internas
var current_level = 0
var next_level = 0
var max_levels = 45
var is_animating = false
var waiting_for_level = false
var next_number_visible = false  # Variable para rastrear si el segundo número está visible
var is_restart = false  # Nueva variable para detectar si es un reinicio del mismo nivel

# Nodos
onready var background = $Background
onready var level_display = $CenterContainer/LevelDisplay
onready var level_number = $CenterContainer/LevelDisplay/LevelNumber
onready var next_level_number = $CenterContainer/LevelDisplay/NextLevelNumber
onready var animation_player = $AnimationPlayer

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

	background.modulate.a = 0
	level_display.modulate.a = 0

	level_number.modulate.a = 1.0
	level_number.visible = true

	next_level_number.modulate.a = 0.0
	next_level_number.visible = false

	level_display.visible = show_numbers

	# Asegurar posicionamiento después del layout
	call_deferred("_sync_next_level_position")

	if not animation_player.is_connected("animation_finished", self, "_on_animation_finished"):
		animation_player.connect("animation_finished", self, "_on_animation_finished")

	if TransitionManager and not TransitionManager.is_connected("level_loaded", self, "_on_level_loaded"):
		TransitionManager.connect("level_loaded", self, "_on_level_loaded")

func _sync_next_level_position():
	next_level_number.rect_position = level_number.rect_position

func start_transition(from_level, to_level):
	if is_animating:
		return

	is_animating = true
	current_level = from_level
	next_level = to_level
	waiting_for_level = false
	next_number_visible = false  # Reiniciamos el estado del segundo número
	
	# Informar a Global que hay una animación en curso
	if Global:
		Global.set_animation_in_progress(true)
	
	# Determinar si es un reinicio del mismo nivel
	is_restart = (from_level == to_level && from_level > 0)

	print("Iniciando transición de animación: ", from_level, " a ", to_level,
		  " (animate_numbers: ", animate_numbers, ", es reinicio: ", is_restart, ")")

	background.modulate.a = 0

	if show_numbers:
		level_number.text = str(current_level).pad_zeros(3)
		next_level_number.text = str(next_level).pad_zeros(3)

		level_number.visible = true
		level_number.modulate.a = 1.0

		next_level_number.visible = false  # Aseguramos que esté oculto al inicio
		next_level_number.modulate.a = 0.0

		level_display.visible = true
	else:
		level_display.visible = false

	# Ajustar velocidad de la animación si es reinicio
	if is_restart:
		animation_player.playback_speed = 2.0  # Más rápido para reinicios (aumentado de 1.5 a 2.0)
	else:
		animation_player.playback_speed = 1.0  # Velocidad normal para nuevos niveles

	animation_player.play("transition_fade_in")

func _on_level_loaded():
	if waiting_for_level:
		# Solo continuamos si el segundo número ya está visible
		if next_number_visible:
			waiting_for_level = false
			print("Nivel listo, continuando con fade_out")
			
			# Pequeña pausa antes de desaparecer
			yield(get_tree().create_timer(0.3), "timeout")
			
			# Animación para desaparecer el nextLevelNumber
			var fade_tween = Tween.new()
			add_child(fade_tween)
			
			fade_tween.interpolate_property(next_level_number, "modulate:a", 
				1.0, 0.0, number_animation_time/2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
				
			fade_tween.start()
			yield(fade_tween, "tween_completed")
			fade_tween.queue_free()
			
			# Continuar con el fade_out normal
			animation_player.play("transition_fade_out")
		else:
			print("Esperando a que el número siguiente sea visible")


func _on_animation_finished(anim_name):
	if anim_name == "transition_fade_in":
		_on_fade_in_completed()
	elif anim_name == "transition_fade_out":
		_on_fade_out_completed()

func _on_fade_in_completed():
	if show_numbers and current_level != next_level and animate_numbers:
		var tween = Tween.new()
		add_child(tween)

		var original_pos = level_number.rect_position
		var animation_duration = number_animation_time
		
		if is_restart:
			animation_duration = animation_duration / 1.5

		# Configurar nextLevelNumber para la animación
		next_level_number.text = str(next_level).pad_zeros(3)
		next_level_number.rect_position = Vector2(original_pos.x, original_pos.y + 60)  # Comienza más abajo
		next_level_number.modulate.a = 0
		next_level_number.visible = true
		
		# Guardar la posición inicial para evitar saltos
		var next_level_start_pos = next_level_number.rect_position

		# Animación del levelNumber (actual) - se mueve hacia arriba y desaparece
		tween.interpolate_property(level_number, "rect_position:y", 
			original_pos.y, original_pos.y - 30, animation_duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.interpolate_property(level_number, "modulate:a", 
			1.0, 0.0, animation_duration, Tween.TRANS_CUBIC, Tween.EASE_OUT)

		# Animación del nextLevelNumber (nuevo)
		# Usamos la variable next_level_start_pos para asegurar consistencia
		tween.interpolate_property(next_level_number, "rect_position:y", 
			next_level_start_pos.y, original_pos.y - 20, animation_duration, 
			Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.3)
		tween.interpolate_property(next_level_number, "modulate:a", 
			0.0, 1.0, animation_duration, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.3)

		tween.start()
		yield(tween, "tween_completed")
		tween.queue_free()

		# Asegurar que la posición final es exactamente la deseada
		next_level_number.rect_position = original_pos
		
		# Ocultar levelNumber original
		level_number.visible = false
		
		# Marcar que el segundo número ya es visible
		next_number_visible = true

	elif show_numbers and current_level != next_level:
		level_number.text = str(next_level).pad_zeros(3)

	print("Emitiendo señal de punto medio de transición")
	emit_signal("transition_mid_point")

	# Animación del segundo número si corresponde
	if show_numbers and current_level != next_level:
		# Configuramos y mostramos el segundo número

		
		var next_tween = Tween.new()
		add_child(next_tween)

		# Posicionamos correctamente el segundo número
		
		next_level_number.modulate.a = 0
		next_level_number.visible = true
		
		var fade_duration = number_animation_time
		if is_restart:
			fade_duration = fade_duration / 1.5  # Más rápido para reinicios

		# Animamos la aparición del segundo número
		next_tween.interpolate_property(next_level_number, "modulate:a", 
			1.0, 1.0, fade_duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)

		next_tween.start()
		yield(next_tween, "tween_completed")
		next_tween.queue_free()
		
		# Marcamos que el segundo número ya es visible
		next_number_visible = true
		
		# Tiempo de espera ajustado según si es reinicio o no
		var display_time = next_number_display_time
		if is_restart:
			display_time = restart_number_display_time
			
		yield(get_tree().create_timer(display_time), "timeout")

	# Manejo de la carga del nivel y continuación de la transición
	if next_level > 0:
		waiting_for_level = true
		print("Esperando a que el nivel esté listo antes de fade_out")
		
		# Si el nivel ya está cargado y el número siguiente ya es visible, continuamos inmediatamente
		if next_number_visible and TransitionManager.is_level_ready():
			print("Nivel ya está listo y número visible, continuando inmediatamente")
			waiting_for_level = false
			animation_player.play("transition_fade_out")
		else:
			# Si el nivel no está listo, esperar la señal
			print("Esperando señal level_loaded o timeout")
			
			# Tiempo de espera como fallback
			var timeout = 0.5
			if is_restart:
				timeout = 1.5
				
			# Crear un timer que servirá como timeout
			var wait_timer = Timer.new()
			wait_timer.one_shot = true
			wait_timer.wait_time = timeout
			add_child(wait_timer)
			wait_timer.start()
			
			# Esperar a que ocurra primero: la señal level_loaded o timeout
			var waiting = true
			while waiting and waiting_for_level:
				# Si el nivel ya está listo mientras esperamos, salir del bucle
				if TransitionManager.is_level_ready() and next_number_visible:
					waiting = false
					waiting_for_level = false
					print("Nivel listo durante espera, continuando")
					break
					
				# Si el timer ha expirado, salir del bucle
				if !wait_timer.time_left:
					waiting = false
					print("Tiempo de espera excedido, continuando de todas formas")
					break
					
				# Esperar un frame
				yield(get_tree(), "idle_frame")
			
			# Limpiar el timer
			wait_timer.stop()
			wait_timer.queue_free()
			
			# Si aún estábamos esperando, continuar de todas formas
			if waiting_for_level:
				waiting_for_level = false
				print("Continuando con fade_out después de espera")
			
			# Reproducir la animación de fade out
			animation_player.play("transition_fade_out")
	else:
		# Para cuando no hay carga de nivel (ej. al salir)
		var wait_time = delay_before_fade_out
		if is_restart:
			wait_time = wait_time / 2
			
		yield(get_tree().create_timer(wait_time), "timeout")
		animation_player.play("transition_fade_out")


func _on_fade_out_completed():
	background.modulate.a = 0

	# Restablecer visibilidad de los números
	level_number.visible = true
	level_number.modulate.a = 1.0
	next_level_number.visible = false
	next_level_number.modulate.a = 0
	next_number_visible = false

	is_animating = false
	
	# Informar a Global que la animación ha terminado
	if Global:
		Global.set_animation_in_progress(false)
		
	print("Emitiendo señal de transición completada")
	emit_signal("transition_completed")
