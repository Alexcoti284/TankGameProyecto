extends Node2D

var cloud_textures = []
var speed = 0
var min_speed = 50
var max_speed = 110
var min_scale = 0.4
var max_scale = 1
var screen_width = 0

func _ready():
	# Set random cloud texture if textures were loaded
	if cloud_textures.size() > 0:

		var cloud_index = randi() % cloud_textures.size()
		$Sprite.texture = cloud_textures[cloud_index]
	
	# Set random speed
	speed = rand_range(min_speed, max_speed)
	
	# Set random scale
	var cloud_scale = rand_range(min_scale, max_scale)
	scale = Vector2(cloud_scale, cloud_scale)
	
	# Set random transparency
	modulate.a = rand_range(0.7, 0.9)

func initialize():	
	for i in range(1, 8): 
		var texture = load("res://Sprites/Clouds/cloud" + str(i) + ".png")
		if texture:
			cloud_textures.append(texture)

func _process(delta):
	# Move the cloud from left to right
	position.x += speed * delta
	
	# If the cloud has moved off the screen, remove it
	if position.x > screen_width + 1000: 
		queue_free()

