extends Node2D

var Blast = preload("res://Escenas/Efectos/Explosion.tscn")

var exploding = false

func _ready():
	AudioManager.play(AudioManager.SOUNDS.MINE)

func setup(position: Vector2):
	self.position = position

func createBlast():
	var blast = Blast.instance()
	blast.position = position
	get_parent().add_child(blast)

func destroy():
	call_deferred("createBlast")
	queue_free()

func _on_TiempoExpiracion_timeout():
	$TiempoExplosion.start()
	$Sonido_Tick.play()
	$AnimationPlayer.play("tick")


func _on_TiempoExplosion_timeout():
	destroy()
