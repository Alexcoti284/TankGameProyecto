extends TileMap

onready var otro_tilemap = get_node("../../")  # Ruta corregida

func _ready():

	otro_tilemap.connect("level_start", self, "on_level_entered")

func generate_new_map():
	randomize()
	var map_width = 30
	var map_height = 17
	var tile_ids = [0, 1, 2]
	var min_cluster_size = 20
	var processed_cells = []
	
	for x in range(0, map_width):
		for y in range(0, map_height):
			var cell_pos = Vector2(x, y)
			# Obtener el tile actual en el otro TileMap (Godot 3 usa get_cell)
			var otro_tile_id = otro_tilemap.get_cell(x, y)
			# Lista de tiles que queremos evitar
			var tiles_bloqueados = [0, 1, 2, 3, 4, 6, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 53, 54, 55]
			
			# Si la celda ya fue procesada o tiene un tile bloqueado, saltarla
			if cell_pos in processed_cells or (otro_tile_id in tiles_bloqueados):
				continue
				
			var random_tile = tile_ids[randi() % tile_ids.size()]
			var cluster_size = randi() % (min_cluster_size + 2) + min_cluster_size
			var cluster_cells = generate_cluster(cell_pos, cluster_size, map_width, map_height)
			
			for cell in cluster_cells:
				otro_tile_id = otro_tilemap.get_cell(cell.x, cell.y)  # Volver a comprobar
				# Solo pintar si la celda está vacía o si no es un tile bloqueado
				if otro_tile_id == -1 or not (otro_tile_id in tiles_bloqueados):
					set_cell(cell.x, cell.y, random_tile)
					processed_cells.append(cell)
	
	update_bitmask_region()

func generate_cluster(start_pos, cluster_size, map_width, map_height):
	var cluster = []
	var to_process = [start_pos]
	
	while to_process.size() > 0 and cluster.size() < cluster_size:
		var current = to_process.pop_front()
		
		if current.x < 0 or current.x >= map_width or current.y < 0 or current.y >= map_height:
			continue
			
		if current in cluster:
			continue
			
		cluster.append(current)
		
		var neighbors = [
			current + Vector2(1, 0),
			current + Vector2(-1, 0),
			current + Vector2(0, 1),
			current + Vector2(0, -1)
		]
		
		neighbors.shuffle()
		to_process += neighbors
	
	return cluster

# Conecta esta función a una señal que se activa cuando entras a un nivel
func on_level_entered():
	# Limpiamos primero cualquier tile previo
	clear()
	# Generamos el nuevo mapa
	generate_new_map()
	
# Codigo alternativo para hacer el mapa entero de 1 color
"""
extends TileMap

func _ready():
	randomize()  # Inicializa el generador de números aleatorios
	var map_width = 30  # Ancho del mapa en tiles
	var map_height = 17  # Alto del mapa en tiles
	var tile_ids = [0, 1, 2]  # IDs de los tiles que quieres usar

	# Seleccionar un ID de tile aleatorio para todo el mapa
	var selected_tile = tile_ids[randi() % tile_ids.size()]

	# Llenar todo el grid con el mismo tile
	for x in range(0, map_width):
		for y in range(0, map_height):
			set_cell(x, y, selected_tile)

	# Actualizar las máscaras de bits automáticamente
	update_bitmask_region()


"""
