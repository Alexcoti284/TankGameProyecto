extends StaticBody2D

export var vertical = false

# Lo llama cuando entra (se rompe el bloque) por primera vez
func _ready():
	if !vertical:
		$AnimationPlayer.play("Default_H")
	else:
		$AnimatedSprite.animation = "Default_V" # Para obtener la animación vertical predeterminada antes de que comience el nivel (congelar antes de comenzar hace que sea necesario)
		$AnimationPlayer.play("Default_V")

func Explosion():
	if !vertical:
		$AnimationPlayer.play("Explota_H")
	else:
		$AnimationPlayer.play("Explota_V")

func _on_AnimatedSprite_animation_finished():
	queue_free()
