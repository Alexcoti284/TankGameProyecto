extends "res://Scripts/StationaryTank.gd"

func _ready():
	if Debug.SHOW_BULLET_RAYCASTS:
		BULLET_RAYCAST_LIST = []
		DEBUG_BOUNCE_SPOT = Vector2(0,0)

	# Configuración inicial del cañón 
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	rotationDirection = 1 if rng.randf() > 0.5 else -1
	
	# Si tienes un timer para controlar el disparo, configúralo aquí
	if has_node("ShootingTimer"):
		$ShootingTimer.wait_time = 1.0 / 1.5  # 1.5 disparos por segundo
		$ShootingTimer.start()

func _physics_process(delta):
	# Rota el cañón continuamente
	cannonRotSpeed = 1
	$Cannon.rotation += delta * rotationDirection * cannonRotSpeed
	
	if okToShoot:
		if Debug.SHOW_BULLET_RAYCASTS:
			BULLET_RAYCAST_LIST.clear()
		
		# Sistema de detección con rebotes (hasta 2 rebotes)
		var shouldShoot = check_player_with_bounces()
		
		if shouldShoot:
			tryToShoot()
			okToShoot = false
			if has_node("ShootingTimer"):
				$ShootingTimer.start()
	
	if Debug.SHOW_BULLET_RAYCASTS:
		update()

# Función para verificar si el jugador está en la trayectoria de la bala (con rebotes)
func check_player_with_bounces():
	# Trayectoria directa
	var firstRaycastResult = castRayForBounce(getCannonTipPosition(), Vector2(1,0).rotated($Cannon.rotation))
	
	if firstRaycastResult:
		if Debug.SHOW_BULLET_RAYCASTS:
			DEBUG_BOUNCE_SPOT = firstRaycastResult.position
		
		# Verificamos si golpea al jugador directamente
		if firstRaycastResult.collider.is_in_group('player'):
			return true
		
		# Verificamos si golpea una pared para calcular rebote
		if firstRaycastResult.collider.is_in_group('walls') and firstRaycastResult.normal.is_normalized():
			var direction = Vector2(1,0).rotated($Cannon.rotation)
			var bounceOrigin = firstRaycastResult.position
			var bounceDirection = direction.bounce(firstRaycastResult.normal)
			
			# Aplicamos un pequeño desplazamiento para evitar colisiones con la misma pared
			bounceOrigin += bounceDirection.normalized() * 0.1
			
			# Primer rebote
			var secondRaycastResult = castRayForBounce(bounceOrigin, bounceDirection)
			if secondRaycastResult:
				# Verificamos si el primer rebote golpea al jugador
				if secondRaycastResult.collider.is_in_group('player'):
					return true
				
				# Verificamos si el primer rebote golpea una pared para calcular un segundo rebote
				if secondRaycastResult.collider.is_in_group('walls') and secondRaycastResult.normal.is_normalized():
					var secondBounceOrigin = secondRaycastResult.position
					var secondBounceDirection = bounceDirection.bounce(secondRaycastResult.normal)
					
					# Aplicamos un pequeño desplazamiento para evitar colisiones con la misma pared
					secondBounceOrigin += secondBounceDirection.normalized() * 0.1
					
					# Segundo rebote
					var thirdRaycastResult = castRayForBounce(secondBounceOrigin, secondBounceDirection)
					if thirdRaycastResult and thirdRaycastResult.collider.is_in_group('player'):
						return true
	
	return false

# Función para el raycast que detecta rebotes
func castRayForBounce(origin: Vector2, direction: Vector2):
	var space_state = get_world_2d().direct_space_state
	var max_distance = 1000
	var blastMask = 0b01111  # Usar la misma máscara que en el script original
	
	# Si estamos usando shape casting
	if "getCollisionShape" in bulletInstance:
		var hit = RayCastUtils.castShape(origin, bulletInstance.getCollisionShape(), direction, space_state, max_distance, BULLET_RAYCAST_LIST, [], blastMask)
		return hit
	# Si preferimos usar raycast simple
	else:
		var hit = space_state.intersect_ray(origin, origin + direction.normalized() * max_distance, [], blastMask)
		if hit and Debug.SHOW_BULLET_RAYCASTS:
			BULLET_RAYCAST_LIST.append([origin, hit.position])
		return hit

# Opcional: Si usas un timer para controlar los disparos
func _on_ShootingTimer_timeout():
	okToShoot = true

# Sobrescribimos _draw para visualizar los raycast en modo debug
func _draw():
	if Debug.SHOW_BULLET_RAYCASTS:
		for i in BULLET_RAYCAST_LIST:
			draw_line(i[0] - position, i[1] - position, Color.red, 1)
		draw_circle(DEBUG_BOUNCE_SPOT - position, 3, Color.green)
