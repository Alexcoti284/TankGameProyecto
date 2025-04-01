extends KinematicBody2D

export (int) var speed = 40
export (float) var rotation_speed = 5.0

var currentDirection: Vector2
var tankRotation = 0.0

export var maxBullets = 1
export var maxMines = 0

var liveBullets = []
var liveMines = []

const Mine = preload("res://Escenas/Mine.tscn")
export var Bullet = preload("res://Escenas/Bullet.tscn")
var bulletInstance = Bullet.instance() # A bullet instance to acces some of ithe Bullet class properties
# Precargar tu efecto de humo existente (ajusta la ruta según donde esté guardada tu escena)
const SmokeEffect = preload("res://Escenas/Efectos/Smoke.tscn")

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
	if (tankRotation <= -(directions.LEFT.angle()) + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"
	elif (tankRotation <= directions.UP_LEFT.angle() + PI/8) :
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotation <= directions.UP.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotation <= directions.UP_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"
	elif (tankRotation <= directions.RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"
	elif (tankRotation <= directions.DOWN_RIGHT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalAbajo"
	elif (tankRotation <= directions.DOWN.angle() + PI/8):
		$AnimationPlayer.current_animation = "Vertical"
	elif (tankRotation <= directions.DOWN_LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "DiagonalArriba"
	elif (tankRotation <= directions.LEFT.angle() + PI/8):
		$AnimationPlayer.current_animation = "Horizontal"

func rotateCannon(angle):
	$Cannon.rotation = angle

func shoot():
	var bullet = Bullet.instance()
	bullet.setup(getCannonTipPosition(), Vector2(1,0).rotated($Cannon.rotation))
	get_parent().add_child(bullet)
	liveBullets.append(bullet)
	
	# Crear efecto de humo usando tu escena existente (más pequeño y sin sonido)
	create_smoke_effect()

	# Pausar el movimiento del tanque por 0.1 segundos
	var original_speed = speed
	speed = 0
	
	# Guardar una referencia débil al timer para evitar problemas si el tanque se destruye
	var timer = get_tree().create_timer(0.1)
	# Conectar la señal timeout directamente en lugar de usar yield
	timer.connect("timeout", self, "_on_shoot_timer_timeout", [original_speed])

# Nueva función para manejar el timeout del timer de disparo
func _on_shoot_timer_timeout(original_speed):
	# Solo restaurar la velocidad si el tanque aún existe
	if is_instance_valid(self):
		speed = original_speed

# Función para crear el efecto de humo (más pequeño y sin sonido)
func create_smoke_effect():
	var smoke = SmokeEffect.instance()
	smoke.position = getCannonTipPosition()
	smoke.rotation = $Cannon.rotation
	
	# Configurar para que sea más pequeño y sin sonido
	smoke.withSound = false  # Desactivar el sonido
	smoke.scale = Vector2(0.5, 0.5)  # Reducir tamaño a la mitad (ajusta según necesites)
	
	get_parent().add_child(smoke)
	
func tryToShoot():
	if ($Cannon.get_overlapping_bodies().empty()): # Validate cannon isn't within a wall
		if (Utils.getNumberOfActiveObjects(liveBullets) < maxBullets):
			shoot()
	
func tryToPlantMine():
	if (Utils.getNumberOfActiveObjects(liveMines) < maxMines):
		plantMine()

func plantMine():
	var mine = Mine.instance()
	mine.position = position
	get_parent().add_child(mine)
	liveMines.append(mine)

func getCannonTipPosition():
	return position + $Cannon.position + Vector2(15,0).rotated($Cannon.rotation)

func destroy():
	AudioManager.play(AudioManager.SOUNDS.TANK_DEATH)
	queue_free()

func _exit_tree():
	bulletInstance.queue_free()
