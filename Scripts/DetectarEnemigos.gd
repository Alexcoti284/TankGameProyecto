extends CanvasItem
const NUMBER_OF_RAYS = 9

static func castShape(origin: Vector2, shape, direction: Vector2, spaceState, rayLength, debugLines: Array, exclude: Array, colmask = 0b11111111):
	
	# Creates an array to store each of the rays base y positions for the shape, based on the NUMBER_OF_RAYS we want
	var FormaYExtent = shape.extents.y
	var rayPaso = 2*FormaYExtent/(NUMBER_OF_RAYS - 1)
	var rayPosicion = []
	for i in range(NUMBER_OF_RAYS):
		rayPosicion.append(-FormaYExtent + i*rayPaso)	

	var CercanoRayCollisionDistance = Global.MAX_INT
	var CercanoRayCollision
	var CercanoRayOffest = 0
	for p in rayPosicion:
		var initPoint = origin + Vector2(0,p).rotated(direction.angle())
		var endPoint = initPoint + direction*rayLength
		var rayColision = spaceState.intersect_ray(initPoint, endPoint, exclude, colmask)
		if debugLines != null: debugLines.append([initPoint, endPoint])
		if rayColision:
			if (rayColision.position.distance_to(origin) < CercanoRayCollisionDistance):
				CercanoRayCollisionDistance = abs(rayColision.position.distance_to(origin))
				CercanoRayCollision = rayColision
				CercanoRayOffest = rayColision.position.distance_to(initPoint)
	if CercanoRayCollision:
		CercanoRayCollision.position = origin + Vector2(1,0).rotated(direction.angle())*CercanoRayOffest 
	return CercanoRayCollision
