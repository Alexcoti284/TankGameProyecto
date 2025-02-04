extends TileMap

func _ready():
	randomize()  # Inicializa el generador de números aleatorios
	var map_width = 29  # Ancho del mapa en tiles
	var map_height = 16  # Alto del mapa en tiles
	var tile_ids = [0, 1, 2]  # IDs de los tiles que quieres usar
	var min_cluster_size = 14  # Tamaño mínimo de un cluster

	# Crear un mapa vacío para rastrear las celdas ya procesadas
	var processed_cells = []

	# Cambiar los bucles para empezar desde 1,1
	for x in range(1, map_width):
		for y in range(1, map_height):
			# Si la celda ya fue procesada, saltarla
			if Vector2(x, y) in processed_cells:
				continue

			# Seleccionar un ID de tile aleatorio
			var random_tile = tile_ids[randi() % tile_ids.size()]

			# Generar un cluster alrededor de la celda actual
			var cluster_size = randi() % (min_cluster_size + 2) + min_cluster_size  # Tamaño aleatorio pero >= min_cluster_size
			var cluster_cells = _generate_cluster(Vector2(x, y), cluster_size, map_width, map_height)

			# Colocar el tile en todas las celdas del cluster
			for cell in cluster_cells:
				set_cell(cell.x, cell.y, random_tile)
				processed_cells.append(cell)

	# Actualizar las máscaras de bits automáticamente
	update_bitmask_region()

# Función para generar un cluster de celdas
func _generate_cluster(start_pos, cluster_size, map_width, map_height):
	var cluster = []
	var to_process = [start_pos]

	while to_process.size() > 0 and cluster.size() < cluster_size:
		var current = to_process.pop_front()

		# Asegurarse de que la celda está dentro de los límites del mapa
		if current.x < 1 or current.x >= map_width or current.y < 1 or current.y >= map_height:
			continue

		# Evitar duplicados
		if current in cluster:
			continue

		# Agregar la celda al cluster
		cluster.append(current)

		# Agregar vecinos aleatorios a la lista de procesamiento
		var neighbors = [
			current + Vector2(1, 0),
			current + Vector2(-1, 0),
			current + Vector2(0, 1),
			current + Vector2(0, -1)
		]
		neighbors.shuffle()  # Mezclar los vecinos para aleatoriedad
		to_process += neighbors

	return cluster
