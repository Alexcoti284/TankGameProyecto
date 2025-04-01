# CloudScene.gd
extends Node2D

var cloud_scene = preload("res://Escenas/Gui/Cloud.tscn")
onready var cloud_container = $ParallaxBackground/CloudLayer/CloudContainer
onready var cloud_timer = $CloudTimer

var screen_size
var min_spawn_time = 1.0
var max_spawn_time = 4.0

func _ready():
	screen_size = get_viewport_rect().size
	randomize()
	set_cloud_timer()
	cloud_timer.connect("timeout", self, "_on_CloudTimer_timeout")
	cloud_timer.start()
	
	# Set up the background layers based on the provided images
	var sky_and_sand = $ParallaxBackground/SkyAndSandLayer/SkyAndSand
	sky_and_sand.texture = load("res://Sprites/Background/sky_and_sand.png")
	sky_and_sand.scale = Vector2(screen_size.x / sky_and_sand.texture.get_width(), 
								screen_size.y / sky_and_sand.texture.get_height())
	
	var mountains2 = $ParallaxBackground/Mountains2Layer/Mountains2
	mountains2.texture = load("res://Sprites/Background/mountains2.png")
	mountains2.position.y = screen_size.y * 0.5  # Position in the middle of the screen
	mountains2.scale = Vector2(screen_size.x / mountains2.texture.get_width(), 1)
	
	var mountains1 = $ParallaxBackground/Mountains1Layer/Mountains1
	mountains1.texture = load("res://Sprites/Background/mountains1.png")
	mountains1.position.y = screen_size.y * 0.6  # Position slightly lower than mountains2
	mountains1.scale = Vector2(screen_size.x / mountains1.texture.get_width(), 1)

func set_cloud_timer():
	cloud_timer.wait_time = rand_range(min_spawn_time, max_spawn_time)

func _on_CloudTimer_timeout():
	spawn_cloud()
	set_cloud_timer()

func spawn_cloud():
	var cloud_instance = cloud_scene.instance()
	
	# Set the cloud's position to start from the left side of the screen
	# at a random height within the top portion (sky area)
	var y_pos = rand_range(0, screen_size.y * 0.4)
	cloud_instance.position = Vector2(-400, y_pos) 

	
	# Set random speed and cloud appearance
	cloud_instance.initialize()
	
	# Add the cloud to the scene
	cloud_container.add_child(cloud_instance)
