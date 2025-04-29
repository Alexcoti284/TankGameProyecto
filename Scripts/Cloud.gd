extends Node2D

var cloud_textures = []
var speed = 0
var min_speed = 50
var max_speed = 110
var min_scale = 0.4
var max_scale = 1
var screen_width = 0
var direction = 1  # 1 = derecha, -1 = izquierda

func _ready():
	if cloud_textures.size() > 0:
		var cloud_index = randi() % cloud_textures.size()
		$Sprite.texture = cloud_textures[cloud_index]
	
	speed = rand_range(min_speed, max_speed)
	
	var cloud_scale = rand_range(min_scale, max_scale)
	scale = Vector2(cloud_scale, cloud_scale)

	# Transparencia aleatoria
	modulate.a = rand_range(0.7, 0.9)

func initialize():	
	for i in range(1, 8): 
		var texture = load("res://Sprites/Clouds/cloud" + str(i) + ".png")
		if texture:
			cloud_textures.append(texture)

func set_direction(dir):
	direction = dir
	# Si la nube va hacia la izquierda, volteamos el sprite horizontalmente
	$Sprite.flip_h = (direction == -1)

func _process(delta):
	position.x += speed * direction * delta
	
	if direction == 1 and position.x > screen_width + 1000:
		queue_free()
	elif direction == -1 and position.x < -1000:
		queue_free()
