extends Control

onready var grid_container = $LevelMenu/ClipControl/GridContainer
var num_grids = 1
var current_grid = 1
var grid_width = 548
var grid_spacing = 0  # Espacio entre grids
var is_animating = false

	
func _ready():
	yield(get_tree(), "idle_frame")  # Espera un frame para obtener dimensiones reales
	num_grids = grid_container.get_child_count()
	grid_width = grid_container.get_child(0).rect_size.x
	grid_spacing = grid_container.get_constant("separation")  # Obtener el espacio entre grids

	setup_level_box()
	connect_level_selected_to_level_box()
	$LevelMenu/ClipControl.rect_clip_content = true

	$LevelMenu/ClipControl/GridContainer.rect_min_size.x = (grid_width + grid_spacing) * num_grids

	update_button_visibility()

func setup_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			var grid_index = grid.get_index()
			var box_index = box.get_index()
			var level_num = box_index + 1 + grid.get_child_count() * grid_index
			box.level_num = level_num

			var is_unlocked = level_num == 1
			if level_num - 1 < Global.niveles_desbloqueados.size():
				is_unlocked = Global.niveles_desbloqueados[level_num - 1]
			box.locked = !is_unlocked

func connect_level_selected_to_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			if not box.is_connected("level_selected", self, "change_to_scene"):
				box.connect("level_selected", self, "change_to_scene")



func change_to_scene(level_num: int):
	Global.nivel_actual = level_num
	var error = get_tree().change_scene("res://Escenas/Main.tscn")
	if error != OK:
		print("Error al cambiar a Main.tscn: ", error)



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
	$LevelMenu/BackButton.disabled = (current_grid == 1)
	$LevelMenu/NextButton.disabled = (current_grid == num_grids)
	$LevelMenu/BackButton.raise()
	$LevelMenu/NextButton.raise()

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
