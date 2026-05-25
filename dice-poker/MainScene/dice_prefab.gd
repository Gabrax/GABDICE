extends RigidBody3D

@onready var sfx = $AudioStreamPlayer3D

var cooldown := false

func _ready():

	body_entered.connect(_on_body_entered)


func _on_body_entered(body):

	if cooldown:
		return

	if linear_velocity.length() > 1.0:

		cooldown = true

		sfx.pitch_scale = randf_range(0.9, 1.1)

		sfx.play()

		await get_tree().create_timer(0.08).timeout

		cooldown = false
