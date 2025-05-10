extends Control

onready var grid_container = $ClipControl/GridContainer
var num_grids = 1
var current_grid = 1
var grid_width = 548
var grid_spacing = 0  # Espacio entre grids
var is_animating = false

	
func _ready():
	# Informar a Global que estamos en el menú
	if Global:
		Global.set_in_menu(true)
	
	# Reproducir la música del menú
	if AudioManager and AudioManager.current_track != AudioManager.TRACKS.MENU:
		AudioManager.startBGMusic(AudioManager.TRACKS.MENU)
	

	num_grids = grid_container.get_child_count()
	grid_width = grid_container.get_child(0).rect_size.x
	grid_spacing = grid_container.get_constant("separation")  # Obtener el espacio entre grids

	setup_level_box()
	connect_level_selected_to_level_box()
	$ClipControl.rect_clip_content = true

	$ClipControl/GridContainer.rect_min_size.x = (grid_width + grid_spacing) * num_grids

	update_button_visibility()
	
	# Asegurarse de que el juego no está pausado en el selector de niveles
	if get_tree().paused:
		get_tree().paused = false
		print("Juego despausado en el selector de niveles")
	
	# Asegurarse de que el menú no está bloqueado
	if Global:
		Global.set_menu_blocked(false)
		print("Menú desbloqueado en selector de niveles")

func _exit_tree():
	# Al salir del menú, actualizar el estado
	if Global:
		Global.set_in_menu(false)

func setup_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			var grid_index = grid.get_index()
			var box_index = box.get_index()
			var level_num = box_index + 1 + grid.get_child_count() * grid_index
			box.level_num = level_num
			
			# Verificar si el nivel está desbloqueado
			var is_unlocked = false
			if level_num - 1 < Global.niveles_desbloqueados.size():
				is_unlocked = Global.niveles_desbloqueados[level_num - 1]
			else:
				is_unlocked = (level_num == 1) # El primer nivel siempre desbloqueado
				
			box.locked = !is_unlocked

func connect_level_selected_to_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			if not box.is_connected("level_selected", self, "change_to_scene"):
				box.connect("level_selected", self, "change_to_scene")

func change_to_scene(level_num: int):
	# Actualizar nivel actual en Global
	Global.nivel_actual = level_num
	
	# Iniciar transición con animación (sin números)
	TransitionManager.change_level(0, level_num, false)

func _on_back_button_pressed():
	if current_grid > 1 and not is_animating:
		current_grid -= 1
		animate_grid_position(grid_container.rect_position.x + grid_width + grid_spacing)
		update_button_visibility()

func _on_next_button_pressed():
	if current_grid < num_grids and not is_animating:
		current_grid += 1
		animate_grid_position(grid_container.rect_position.x - (grid_width + grid_spacing))
		update_button_visibility()

func update_button_visibility():
	$ArrowRight/BackButton.disabled = (current_grid == 1)
	$ArrowLeft/NextButton.disabled = (current_grid == num_grids)
	$ArrowRight/BackButton.raise()
	$ArrowLeft/NextButton.raise()

func animate_grid_position(final_value):
	if is_animating:
		return

	is_animating = true
	final_value = clamp(final_value, -((grid_width + grid_spacing) * (num_grids - 1)), 0)

	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(grid_container, "rect_position:x", 
		grid_container.rect_position.x, final_value, 0.5, 
		Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()

	grid_container.rect_position.x = final_value

	is_animating = false
	update_button_visibility()
