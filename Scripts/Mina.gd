extends Node2D

var Explosion = preload("res://Escenas/Efectos/Explosion.tscn")

var exploding = false

func _ready():
	AudioManager.play(AudioManager.SOUNDS.MINE)

func setup(position: Vector2):
	self.position = position

func crearExplosion():
	var explosion = Explosion.instance()
	explosion.position = position
	get_parent().add_child(explosion)

func destroy():
	call_deferred("crearExplosion")
	queue_free()

func _on_TiempoExpiracion_timeout():
	$TiempoExplosion.start()
	$Sonido_Tick.play()
	$AnimationPlayer.play("tick")


func _on_TiempoExplosion_timeout():
	destroy()
