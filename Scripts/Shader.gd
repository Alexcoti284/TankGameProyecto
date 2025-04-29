extends ColorRect

# Referencia al material del shader
onready var shader_material = material

# Variables para guardar el estado del shader
var shader_active = true

func _ready():
	# Asegúrate de que el material existe
	if shader_material == null:
		print("Error: No hay material de shader asignado al ColorRect")
		return
	
	# Inicializa según el estado global
	shader_active = Global.shader_enabled
	update_shader_state()

func _process(_delta):
	# Verifica si ha cambiado el estado global del shader
	if shader_active != Global.shader_enabled:
		shader_active = Global.shader_enabled
		update_shader_state()
	
	# Código para atajo de teclado comentado - descomentarlo si configuras la acción
	# if Input.is_action_just_pressed("toggle_shader"):
	#	Global.toggle_shader()

func update_shader_state():
	if shader_active:
		# Asegúrate de que el material está activado
		if material == null:
			material = shader_material
		# Puedes mostrar un mensaje de depuración
		print("Shader activado")
	else:
		# Desactiva el shader
		if material != null:
			material = null
		print("Shader desactivado")
