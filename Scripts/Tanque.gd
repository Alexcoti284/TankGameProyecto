extends KinematicBody2D

export (int) var speed = 40
export (float) var rotation_speed = 5.0

var currentDirection: Vector2
var tankRotation = 0.0

export var maxBullets = 1
export var maxMines = 0

var BalasVivas = []
var MinasVivas = []

const Mine = preload("res://Escenas/Mina.tscn")
export var Bala = preload("res://Escenas/Bala.tscn")
var bulletInstance = Bala.instance() # A bullet instance to acces some of ithe Bullet class properties
# TODO CHANGE FOR GAST BULLET ON GREENT TANK AND OTHERS

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
	return (tankRotation > direction - rotDelta) && (tankRotation < direction + rotDelta)

func move(delta, direction):
	var rotation_dir = 0
	var rotDelta = rotation_speed * delta

	# Find best direction to rotate towards (direction / -direction)
	var angleToDirection = abs(Vector2(1,0).rotated(tankRotation).angle_to(direction))
	var angleToOppositeDirection = abs(Vector2(1,0).rotated(tankRotation).angle_to(-direction))
	var closerDirection = direction
	if !(min(angleToDirection, angleToOppositeDirection) == angleToDirection):
		closerDirection = -direction	
	
	# Rotate tank towards desired direction if it's not already alligned with it
	# If it is, move towards that direction
	if (!isRotationWithinDeltaForDirection(closerDirection.angle(), rotDelta)):
		if (tankRotation > closerDirection.angle()):
			rotation_dir = -1
		else:
			rotation_dir = 1
		
		# Only one tankRotation is counted
		if (tankRotation > PI):
			tankRotation = -PI + (tankRotation - PI)
		if (tankRotation < -PI):
			tankRotation = PI - (tankRotation + PI)
		
		tankRotation += rotation_dir * rotDelta
		updateRotationAnimation()
	else:
		currentDirection = direction
		# warning-ignore:return_value_discarded
		move_and_slide(direction.normalized() * speed)


func updateRotationAnimation():
	if (tankRotation <= -(directions.LEFT.angle()) + PI/8 || tankRotation >= directions.RIGHT.angle() - PI/8):
		$AnimationPlayer.current_animation = "Horizontal"
	elif (tankRotation <= directions.UP_LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotation <= directions.UP.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotation <= directions.UP_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"
	elif (tankRotation <= directions.DOWN_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotation <= directions.DOWN.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotation <= directions.DOWN_LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"

func rotateCannon(angle):
	$"Cañon".rotation = angle

func shoot():
	var BalaD = Bala.instance()
	BalaD.setup(getCannonTipPosition(), Vector2(1,0).rotated($"Cañon".rotation))
	get_parent().add_child(BalaD)
	BalasVivas.append(BalaD)

func tryToShoot():
	if ($"Cañon".get_overlapping_bodies().empty()): 
		if (Utils.getNumberOfActiveObjects(BalasVivas) < maxBullets):
			shoot()

func tryToPlantMine():
	if (Utils.getNumberOfActiveObjects(MinasVivas) < maxMines):
		plantMine()

func plantMine():
	var mine = Mine.instance()
	mine.position = position
	get_parent().add_child(mine)
	MinasVivas.append(mine)

func getCannonTipPosition():
	return position + $"Cañon".position + Vector2(15,0).rotated($"Cañon".rotation)

func destroy():
	AudioManager.play(AudioManager.SOUNDS.TANK_DEATH)
	queue_free()

func _exit_tree():
	bulletInstance.queue_free()
