extends "res://Scripts/TanqueEnemigo.gd"

var direction

var changeDirTimes = [1.5, 3.0]
var mineTimes = [2.0, 4.0]

var collisionCheckDistance = 20
var movementCollisionMask = ~0b1000 # "~" filps the bits to avoids the cannon on layer 4

var MOVEMENT_RAYCAST_LIST: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	if Debug.SHOW_MOVEMENT_RAYCASTS: MOVEMENT_RAYCAST_LIST = []

	direction = directions.values()[(rng.randi_range(0, directions.size() - 1))]
	$TiempoCanviarDireccion.wait_time = rng.randf_range(changeDirTimes[0], changeDirTimes[1])
	RotacionCanon = 0.4

	if (maxMines > 0):
		$TiempoMina.wait_time = rng.randf_range(mineTimes[0], mineTimes[1])
		$TiempoMina.start()

func _physics_process(delta):
	if Debug.SHOW_MOVEMENT_RAYCASTS: MOVEMENT_RAYCAST_LIST.clear()
	var selfToP1Vector = Global.p1Position - position
	var angleToPlayer = Vector2(1,0).rotated($"Cañon".rotation).angle_to(selfToP1Vector)
	if (angleToPlayer > 0):
		rotacionDireccion = 1
	else:
		rotacionDireccion = -1
	self.mover(delta, direction)

func _draw():
	if Debug.SHOW_MOVEMENT_RAYCASTS:
		for i in MOVEMENT_RAYCAST_LIST:
			draw_line(i[0] - position, i[1] - position, Color(255, 0, 0), 1)

func _on_TiempoCanviarDireccion_timeout():
	var spaceState = get_world_2d().direct_space_state
	#Sumando el tamaño de la matriz para poder obtener el Índice de Dirección-1 actual en caso de usar la primera dirección
	var currentDirectionIndex = directions.values().find(currentDirection) + directions.values().size()
	var posibleDirections = []

	for i in range(currentDirectionIndex-1, currentDirectionIndex+2):
		var raycastResult = DetectarEnemigos.castShape(position, $CollisionShape2D.shape, directions.values()[i%directions.size()], spaceState, 40, MOVEMENT_RAYCAST_LIST, [self], movementCollisionMask)
		if (!raycastResult):
			posibleDirections.append(directions.values()[i%directions.size()])
	if Debug.SHOW_MOVEMENT_RAYCASTS: update()
	if (posibleDirections != []):
		direction = posibleDirections[(rng.randi_range(0, posibleDirections.size()-1))]
	$TiempoCanviarDireccion.wait_time = rng.randf_range(changeDirTimes[0], changeDirTimes[1])


func _on_TiempoComprovarColision_timeout():
	var spaceState = get_world_2d().direct_space_state
	# Sumando el tamaño de la matriz para poder obtener el Índice de Dirección-1 actual en caso de usar la primera dirección
	var currentDirectionIndex = directions.values().find(currentDirection) + directions.values().size()
	var straightRaycastResult = DetectarEnemigos.castShape(position, $CollisionShape2D.shape, directions.values()[currentDirectionIndex%directions.size()], spaceState, collisionCheckDistance, MOVEMENT_RAYCAST_LIST, [self], movementCollisionMask)
	if Debug.SHOW_MOVEMENT_RAYCASTS: update()
	if straightRaycastResult:
		var posibleDirections = []
		for i in range(currentDirectionIndex-2, currentDirectionIndex+3):
			var posibleDirectionRaycastResult = DetectarEnemigos.castShape(position, $CollisionShape2D.shape, directions.values()[i%directions.size()], spaceState, collisionCheckDistance, MOVEMENT_RAYCAST_LIST, [self], movementCollisionMask)
			if (!posibleDirectionRaycastResult):
				posibleDirections.append(directions.values()[i%directions.size()])
		#Si las tres direcciones estan hacia una colision, entra en los if de las 2 posiciones extras
		if (posibleDirections.empty()):
			var alternativeDirecttions = []
			alternativeDirecttions.append(directions.values()[(currentDirectionIndex-3)%directions.size()])
			alternativeDirecttions.append(directions.values()[(currentDirectionIndex+3)%directions.size()])
			alternativeDirecttions.append(directions.values()[(currentDirectionIndex+4)%directions.size()])
			for i in alternativeDirecttions:
				var alternativeDirectionRaycastResult = DetectarEnemigos.castShape(position, $CollisionShape2D.shape, i, spaceState, collisionCheckDistance, MOVEMENT_RAYCAST_LIST, [self], movementCollisionMask)
				if (!alternativeDirectionRaycastResult):
					posibleDirections.append(i)
		if (!posibleDirections.empty()):
			direction = posibleDirections[(rng.randi_range(0, posibleDirections.size()-1))]
		else:
			direction = directions.values()[(rng.randi_range(0, directions.size()-1))]


func _on_TiempoMina_timeout():
	tryToPlantMine()
	$TiempoMina.wait_time = rng.randf_range(mineTimes[0], mineTimes[1])
