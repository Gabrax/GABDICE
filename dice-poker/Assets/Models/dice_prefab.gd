extends RigidBody3D

@onready var sfx = $AudioStreamPlayer3D

var cooldown := false
var stopped_sent := false
var sync_timer := 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	if cooldown:
		return

	if linear_velocity.length() > 1.0:
		cooldown = true
		sfx.pitch_scale = randf_range(0.9, 1.1)
		sfx.play()
		await get_tree().create_timer(0.08).timeout
		cooldown = false
	
func _physics_process(delta):

	if !multiplayer.is_server():
		return

	if linear_velocity.length() < 0.01 \
	and angular_velocity.length() < 0.01:

		if !stopped_sent:
			stopped_sent = true

			sync_transform.rpc(
				global_position,
				global_rotation,
				Vector3.ZERO,
				Vector3.ZERO
			)

		return

	stopped_sent = false

	sync_timer += delta

	if sync_timer >= 0.05:
		sync_timer = 0.0

		sync_transform.rpc(
			global_position,
			global_rotation,
			linear_velocity,
			angular_velocity
		)
	
@rpc("authority", "call_remote", "unreliable")
func sync_transform(pos, rot, lin_vel, ang_vel):
	if multiplayer.is_server():
		return

	global_position = pos
	global_rotation = rot

	linear_velocity = lin_vel
	angular_velocity = ang_vel

	sleeping = linear_velocity.length() < 0.01 \
		and angular_velocity.length() < 0.01
