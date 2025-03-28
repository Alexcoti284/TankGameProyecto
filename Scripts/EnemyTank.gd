extends "res://Scripts/Tank.gd"

var RayCastUtils = preload("res://Scripts/RayCastUtils.gd")

var rotationDirection = 1
var cannonRotSpeed = 1.5
export var bulletsPerSecond = 0.5
var rng = RandomNumberGenerator.new()
var fireRate 
var okToShoot = false

var BULLET_RAYCAST_LIST: Array
var DEBUG_BOUNCE_SPOT: Vector2

signal killed

func _ready():
	if Debug.SHOW_BULLET_RAYCASTS:
		BULLET_RAYCAST_LIST = []
		DEBUG_BOUNCE_SPOT = Vector2(0,0)

	fireRate = rng.randf_range((1/bulletsPerSecond)-(1/bulletsPerSecond)/5, (1/bulletsPerSecond)-(1/bulletsPerSecond)/5)
	rng.randomize()
	$ShootingTimer.wait_time = fireRate

	# Apuntar el cañón hacia el jugador con un pequeño offset aleatorio
	var orientation = [-1,1]
	var vecToPlayer = position.direction_to(Global.p1Position)
	rotationDirection = orientation[rng.randi_range(0,1)]
	$Cannon.rotation = vecToPlayer.rotated(rotationDirection * PI/4).angle()

func _physics_process(delta):
	$Cannon.rotation += delta * rotationDirection * cannonRotSpeed
	if okToShoot:
		if Debug.SHOW_BULLET_RAYCASTS:
			BULLET_RAYCAST_LIST.clear()
		
		var raycastResult = castBulletIgnoringTiles(getCannonTipPosition(), Vector2(1,0).rotated($Cannon.rotation))

		if raycastResult && raycastResult.collider.is_in_group('player'):
			tryToShoot()
			okToShoot = false

	if Debug.SHOW_BULLET_RAYCASTS:
		update()

func _on_ShootingTimer_timeout():
	if !okToShoot:
		okToShoot = true
	$ShootingTimer.wait_time = fireRate
	
func _draw():
	if Debug.SHOW_BULLET_RAYCASTS:
		for i in BULLET_RAYCAST_LIST:
			draw_line(i[0] - position, i[1] - position, Color.red, 1)
		draw_circle(DEBUG_BOUNCE_SPOT - position, 1, Color.blue)

# Nueva función que ignora cualquier cantidad de TileSets del grupo 'pass_through'
func castBulletIgnoringTiles(origin: Vector2, bulletDir):
	var blastMask = 0b01111  
	var max_distance = 1000  
	var current_origin = origin
	var hit

	while true:
		hit = RayCastUtils.castShape(current_origin, bulletInstance.getCollisionShape(), bulletDir, get_world_2d().direct_space_state, max_distance, BULLET_RAYCAST_LIST, [], blastMask)

		if hit:
			# Si impacta con el jugador, lo detectamos
			if hit.collider.is_in_group("player"):
				return hit
			# Si impacta con un obstáculo sólido (pared, tanque enemigo, etc.), se detiene
			elif !hit.collider.is_in_group("pass_through"):
				return null  
			# Si impacta con un TileSet del grupo 'pass_through', sigue buscando más allá
			else:
				current_origin = hit.position + bulletDir.normalized() * 10  
		else:
			break  

	return null

func destroy():
	remove_from_group("enemy")
	emit_signal("killed")
	.destroy()
