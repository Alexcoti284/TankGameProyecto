extends KinematicBody2D

export (int) var velocidad = 40
export (float) var velocidad_rotacion = 5.0

var currentDirection: Vector2
var tankRotacion = 0.0

export var maxBalas = 1
export var maxMines = 0

var BalasVivas = []
var MinasVivas = []

const Mina = preload("res://Escenas/Mina.tscn")
export var Bala = preload("res://Escenas/Bala.tscn")
var bulletInstance = Bala.instance() 
# Incatnciamos la bala para acceder a las propiedades dentro del script de la bala

# CANVIAR PARA TANKES CON BALAS POTENTES I TANKES SIN MOVIMIENTO

var directions = {
	"UP": Vector2(0,-1),
	"UP_RIGHT": Vector2(1,-1),
	"RIGHT": Vector2(1,0),
	"DOWN_RIGHT": Vector2(1,1),
	"DOWN": Vector2(0,1),
	"DOWN_LEFT": Vector2(-1,1),
	"LEFT": Vector2(-1,0),
	"UP_LEFT": Vector2(-1,-1),
}

func isRotationWithinDeltaForDirection(direction, rotDelta):
	return (tankRotacion > direction - rotDelta) && (tankRotacion < direction + rotDelta)

func mover(delta, direction):
	var rotacion_dir = 0
	var rotDelta = velocidad_rotacion * delta

	# Encuenntra cual es la direccion que menos tarda en llegar a la direccion deseada (hace menor recorrido), i la nimacion es mas corta (direccion / -direccion)
	var angleToDirection = abs(Vector2(1,0).rotated(tankRotacion).angle_to(direction))
	var angleToOppositeDirection = abs(Vector2(1,0).rotated(tankRotacion).angle_to(-direction))
	var closerDirection = direction
	if !(min(angleToDirection, angleToOppositeDirection) == angleToDirection):
		closerDirection = -direction
	
	# Rota el tanque a la direccion deseada si no esta en ella
	# Si ya esta en esa direccion se mueve hacia delante
	if (!isRotationWithinDeltaForDirection(closerDirection.angle(), rotDelta)):
		if (tankRotacion > closerDirection.angle()):
			rotacion_dir = -1
		else:
			rotacion_dir = 1
		
		# Solo se cuenta una rotacion del tanque en caso de que haya varias formas de llegar
		if (tankRotacion > PI):
			tankRotacion = -PI + (tankRotacion - PI)
		if (tankRotacion < -PI):
			tankRotacion = PI - (tankRotacion + PI)
		
		tankRotacion += rotacion_dir * rotDelta
		updateRotationAnimation()
	else:
		currentDirection = direction
		
		# warning-ignore:return_value_discarded
		move_and_slide(direction.normalized() * velocidad)


func updateRotationAnimation():
	if (tankRotacion <= -(directions.LEFT.angle()) + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"
	elif (tankRotacion <= directions.UP_LEFT.angle() + PI/8) :
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotacion <= directions.UP.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotacion <= directions.UP_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"
	elif (tankRotacion <= directions.RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"
	elif (tankRotacion <= directions.DOWN_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotacion <= directions.DOWN.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotacion <= directions.DOWN_LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"
	elif (tankRotacion <= directions.LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"

func rotarCanon(angle):
	$"Cañon".rotation = angle

func shoot():
	var BalaD = Bala.instance()
	BalaD.setup(getCannonTipPosition(), Vector2(1,0).rotated($"Cañon".rotation))
	get_parent().add_child(BalaD)
	BalasVivas.append(BalaD)

func tryToShoot():
	if ($"Cañon".get_overlapping_bodies().empty()): 
		if (Utils.getNumberOfActiveObjects(BalasVivas) < maxBalas):
			shoot()

func tryToPlantMine():
	if (Utils.getNumberOfActiveObjects(MinasVivas) < maxMines):
		plantaMina()

func plantaMina():
	var mina = Mina.instance()
	mina.position = position
	get_parent().add_child(mina)
	MinasVivas.append(mina)

func getCannonTipPosition():
	return position + $"Cañon".position + Vector2(15,0).rotated($"Cañon".rotation)

func destroy():
	AudioManager.play(AudioManager.SOUNDS.TANK_DEATH)
	queue_free()

func _exit_tree():
	bulletInstance.queue_free()
