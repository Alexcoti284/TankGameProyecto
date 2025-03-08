extends StaticBody2D

export var vertical = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if !vertical:
		$AnimationPlayer.play("Default_H")
	else:
		$AnimatedSprite.animation = "Default_V" # To get the default vertical animation before the level begins (Freeze before start makes this necessary)
		$AnimationPlayer.play("Default_V")

func blast():
	if !vertical:
		$AnimationPlayer.play("Explota_H")
	else:
		$AnimationPlayer.play("Explota_V")

func _on_AnimatedSprite_animation_finished():
	queue_free()
