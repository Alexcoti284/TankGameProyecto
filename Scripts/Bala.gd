extends KinematicBody2D

var Explosion = preload("res://Escenas/Efectos/Explosion.tscn")
var Ricochet = preload("res://Escenas/Efectos/Rebote.tscn")
var Humo = preload("res://Escenas/Efectos/Humo.tscn")

export var velocidad = 150.0
export var RebotesMax = 1
var RebotesActu
var velocity = Vector2()

class_name Bala

# Called when the node enters the scene tree for the first time.
func _ready():
	AudioManager.play(AudioManager.SOUNDS.SHOT)

func setup(initialPosition: Vector2, initialVelocity: Vector2):
	position = initialPosition
	self.velocity = initialVelocity.normalized()
	RebotesActu = 0
	self.rotation = initialVelocity.angle()

func destroy():
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var collision = move_and_collide(velocity*delta*velocidad)
	if (collision):
		if (collision.collider.get_groups().has("Destruible")):
			if (!collision.collider.get_groups().has("No_Explotable")):
				createExplosion(collision.collider.position)
			collision.collider.destroy()
			AudioManager.play(AudioManager.SOUNDS.BULLET_SHOT)
			self.destroy()
		else: # Collision with walls
			if (RebotesActu >= RebotesMax):
				instanceSmoke(true)
				queue_free()
			else: 
				velocity = velocity.bounce(collision.normal)
				self.rotation = velocity.angle()
				RebotesActu += 1;
				
				# Ricochet
				var ricochet = Ricochet.instance()
				ricochet.position = position - collision.normal*$CollisionShape2D.shape.extents.x
				ricochet.rotate(collision.normal.angle())
				get_parent().add_child(ricochet)
				AudioManager.play(AudioManager.SOUNDS.BOUNCE)

func createExplosion(colliderPosition):
	var explosion = Explosion.instance()
	explosion.position = colliderPosition
	get_parent().add_child(explosion)

func getCollisionShapeExtents():
	return $CollisionShape2D.shape.extents
	
func getCollisionShape() -> Shape:
	return $CollisionShape2D.shape

func instanceSmoke(sound):
	var humo = Humo.instance()
	humo.position = position
	humo.withSound = sound
	get_parent().add_child(humo)
