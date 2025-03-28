extends Control

onready var grid_container = $GridContainer
var num_grids = 1
var current_grid = 1
var grid_width = 548

func _ready():
	num_grids = grid_container.get_child_count()
	grid_width = grid_container.rect_min_size.x
	setup_level_box()
	connect_level_selected_to_level_box()

func setup_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			box.level_num = box.get_index() + 1 + grid.get_child_count() * grid.get_index()
			box.locked = false
	#grid_container.get_child(0).get_child(0).locked = false

func connect_level_selected_to_level_box():
	for grid in grid_container.get_children():
		for box in grid.get_children():
			box.connect("level_selected", self, "change_to_scene")

func change_to_scene(level_num: int):
	var next_level: String = "res://Escenas/Niveles/Level" + str(level_num) + ".tscn"
	if File.new().file_exists(next_level): 
		get_tree().change_scene(next_level)

func _on_back_button_pressed():
	if current_grid > 1:
		current_grid -= 1
		animateGridPosition(grid_container.rect_position.x + grid_width)

func _on_next_button_pressed():
	if current_grid < num_grids:
		current_grid += 1
		animateGridPosition(grid_container.rect_position.x - grid_width)

func animateGridPosition(finalValue):
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(grid_container, "rect_position:x", 
		grid_container.rect_position.x, finalValue, 0.5, 
		Tween.TRANS_BACK, Tween.EASE_OUT)
	tween.start()
