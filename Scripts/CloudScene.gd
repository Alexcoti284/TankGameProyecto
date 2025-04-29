extends Node2D

var cloud_scene = preload("res://Escenas/Gui/Cloud.tscn")
onready var cloud_container = $ParallaxBackground/CloudLayer/CloudContainer
onready var cloud_timer = $CloudTimer
var screen_size
var min_spawn_time = 2.0
var max_spawn_time = 6.0

func _ready():
	screen_size = get_viewport_rect().size
	randomize()

	# Generar solo 1 o 2 nubes iniciales
	for _i in range(randi() % 2 + 1):  # Genera 1 o 2 nubes
		spawn_cloud()

	# Disparar una nube inmediatamente
	spawn_cloud()

	# Iniciar el timer con un primer tiempo aleatorio
	set_cloud_timer()
	cloud_timer.connect("timeout", self, "_on_CloudTimer_timeout")
	cloud_timer.start()

	# Ajustes de fondo (igual que antes)
	var sky_and_sand = $ParallaxBackground/SkyAndSandLayer/SkyAndSand
	sky_and_sand.texture = load("res://Sprites/Background/sky_and_sand.png")
	sky_and_sand.scale = Vector2(screen_size.x / sky_and_sand.texture.get_width(), 
								screen_size.y / sky_and_sand.texture.get_height())
	
	var mountains2 = $ParallaxBackground/Mountains2Layer/Mountains2
	mountains2.texture = load("res://Sprites/Background/mountains2.png")
	mountains2.position.y = screen_size.y * 0.5
	mountains2.scale = Vector2(screen_size.x / mountains2.texture.get_width(), 1)
	
	var mountains1 = $ParallaxBackground/Mountains1Layer/Mountains1
	mountains1.texture = load("res://Sprites/Background/mountains1.png")
	mountains1.position.y = screen_size.y * 0.6
	mountains1.scale = Vector2(screen_size.x / mountains1.texture.get_width(), 1)

func set_cloud_timer():
	cloud_timer.wait_time = rand_range(min_spawn_time, max_spawn_time)

func _on_CloudTimer_timeout():
	spawn_cloud()
	set_cloud_timer()

func spawn_cloud():
	var cloud_instance = cloud_scene.instance()
	var from_left = randf() > 0.5
	var y_pos = rand_range(0, screen_size.y * 0.9)
	
	cloud_instance.initialize()
	cloud_instance.screen_width = screen_size.x
	
	if from_left:
		cloud_instance.position = Vector2(-400, y_pos)
		cloud_instance.set_direction(1)
	else:
		cloud_instance.position = Vector2(screen_size.x + 400, y_pos)
		cloud_instance.set_direction(-1)
	
	cloud_container.add_child(cloud_instance)
