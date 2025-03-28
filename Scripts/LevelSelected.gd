extends Control

onready var grid_container = $LevelMenu/ClipControl/GridContainer
var num_grids = 1
var current_grid = 1
var grid_width = 548

func _ready():
	num_grids = grid_container.get_child_count()
	grid_width = grid_container.rect_size.x 
	setup_level_box()
	connect_level_selected_to_level_box()

func setup_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			# Asignar número de nivel
			var level_num = box.get_index() + 1 + grid.get_child_count() * grid.get_index()
			box.set_meta("level_num", level_num)
			
			# Manejo de niveles desbloqueados
			if level_num > Global.niveles_desbloqueados.size():
				Global.niveles_desbloqueados.resize(level_num)
				Global.niveles_desbloqueados.fill(false)
			
			# Forzar que el primer nivel esté desbloqueado
			if level_num == 1:
				Global.niveles_desbloqueados[0] = true
			
			var locked = not Global.niveles_desbloqueados[level_num - 1]
			box.locked = locked

func connect_level_selected_to_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			if box.has_signal("level_selected"):
				box.connect("level_selected", self, "change_to_scene")

func change_to_scene(level_num: int):
	# Updated to use zero-padded level number and correct path
	var level_str = "Level" + str(level_num).pad_zeros(3)
	var next_level = "res://Escenas/Niveles/" + level_str + ".tscn"
	
	var file = File.new()
	if file.file_exists(next_level):
		Global.nivel_actual = level_num
		var error = get_tree().change_scene(next_level)
		if error != OK:
			print("Error al cambiar de escena: ", error)
	else:
		print("Level scene not found: ", next_level)

func _on_back_button_pressed():
	if current_grid > 1:
		current_grid -= 1
		animate_grid_position(grid_container.rect_position.x + grid_width)

func _on_next_button_pressed():
	if current_grid < num_grids:
		current_grid += 1
		animate_grid_position(grid_container.rect_position.x - grid_width)

func animate_grid_position(final_value):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(grid_container, "rect_position:x", 
		grid_container.rect_position.x, final_value, 0.5, 
		Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	tween.queue_free()
