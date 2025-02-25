extends "res://Scripts/Tanque.gd"


var DetectarEnemigos = preload("res://Scripts/DetectarEnemigos.gd")

var rotacionDireccion = 1
var RotacionCanon = 1.5
export var balasPorSec = 0.5
var rng = RandomNumberGenerator.new()
var fireRate # calculated based on bulletsPerSecond
var PuedeDisparar = false

var BULLET_RAYCAST_LIST: Array
var DEBUG_BOUNCE_SPOT: Vector2

signal Muerto

func _ready():
	if Debug.SHOW_BULLET_RAYCASTS:
		BULLET_RAYCAST_LIST = []
		DEBUG_BOUNCE_SPOT = Vector2(0,0)

	fireRate = rng.randf_range((1/balasPorSec)-(1/balasPorSec)/5, (1/balasPorSec)-(1/balasPorSec)/5)
	rng.randomize()
	$TimepoDisparo.wait_time = fireRate

	# Point cannon towards player, but add a +-PI/4 offset so that we arent pointing dead-on towards him but rather close to him instead
	var orientation = [-1,1]
	var vecToPlayer = position.direction_to((Global.p1Position))
	rotacionDireccion = orientation[rng.randi_range(0,1)]
	$"Cañon".rotation = vecToPlayer.rotated(rotacionDireccion*PI/4).angle()

func _physics_process(delta):
	$"Cañon".rotation += delta * rotacionDireccion * RotacionCanon
	if(PuedeDisparar):
		if Debug.SHOW_BULLET_RAYCASTS: BULLET_RAYCAST_LIST.clear()
		var raycastResult = castBullet(getCannonTipPosition(), Vector2(1,0).rotated($"Cañon".rotation))
		# A non normalized result indicates the collision happened inside the collider, so we ignore it
		if (raycastResult && raycastResult.normal.is_normalized()):
			if Debug.SHOW_BULLET_RAYCASTS: DEBUG_BOUNCE_SPOT = raycastResult.position
			if(raycastResult.collider.is_in_group('Jugador')):
				tryToShoot()
				PuedeDisparar = false
			elif(raycastResult.collider.is_in_group('Pared') && bulletInstance.RebotesMax == 1):
				var dirVector = Vector2(1,0).rotated($"Cañon".rotation)
				# newOrigin will substract bullets size to better allign with bounce
				var newOrigin = raycastResult.position - dirVector.normalized()*bulletInstance.getCollisionShapeExtents().x
				var secondRaycastResult = castBullet(newOrigin, dirVector.bounce(raycastResult.normal))
				if(secondRaycastResult && secondRaycastResult.collider.is_in_group('Jugador')):
					tryToShoot()
					PuedeDisparar = false
	if Debug.SHOW_BULLET_RAYCASTS: update()

func _on_TimepoDisparo_timeout():
	if (!PuedeDisparar):
		PuedeDisparar = true
	$TimepoDisparo.wait_time = fireRate
	
	
func _draw():
	if Debug.SHOW_BULLET_RAYCASTS:
		for i in BULLET_RAYCAST_LIST:
			draw_line(i[0] - position, i[1] - position, Color.red, 1)
		draw_circle(DEBUG_BOUNCE_SPOT - position, 1, Color.blue)

func castBullet(origin: Vector2, bulletDir):
	var blastMask = 0b01111 # Blast detection occurs on layer 5 (value 4 0b10000), we want to ignore them when casting bullets, so we zero that bit
	return DetectarEnemigos.castShape(origin, bulletInstance.getCollisionShape(), bulletDir, get_world_2d().direct_space_state, 1000, BULLET_RAYCAST_LIST, [], blastMask)

func destroy():
	remove_from_group("Enemigo")
	emit_signal("Muerto")
	.destroy()



