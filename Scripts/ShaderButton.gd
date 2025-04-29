extends TextureButton

# Referencia a las texturas que usaremos para los estados
var shader_on_texture: Texture
var shader_off_texture: Texture
var hover_texture: Texture

func _ready():
	# Guarda las texturas de referencia al inicio
	shader_on_texture = preload("res://Sprites/Free-TDS-Game-UI-Pixel-Art/BTN_Exit.png") 
	shader_off_texture = preload("res://Sprites/Free-TDS-Game-UI-Pixel-Art/Levels Menu/2.png") 
	hover_texture = preload("res://Sprites/Free-TDS-Game-UI-Pixel-Art/Levels Menu/1.png") 
	
	# Asegúrate de que el icono del botón refleje el estado actual del shader
	update_button_textures()
	
func _on_ShaderButton_pressed():
	# Cambia el estado del shader
	Global.toggle_shader()
	
	# Actualiza el icono del botón
	update_button_textures()

func update_button_textures():
	# Actualiza el icono del botón según el estado del shader
	if Global.shader_enabled:
		# Cuando el shader está activado
		texture_normal = shader_on_texture
		texture_hover = shader_on_texture  # Sin efecto hover cuando está desactivado

	else:
		# Cuando el shader está desactivado
		texture_normal = hover_texture
		texture_hover = shader_off_texture  # Usar el efecto hover cuando el shader está activado
