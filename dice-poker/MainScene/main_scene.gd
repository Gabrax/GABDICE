extends Node3D

@export var dice_scene: PackedScene

var charge := 0.0

const MAX_FORCE := 0.01
const CHARGE_SPEED := 0.01

func _process(delta):

	if Input.is_action_pressed("ui_accept"):
		charge += CHARGE_SPEED * delta
		charge = clamp(charge, 0.0, MAX_FORCE)

	if Input.is_action_just_released("ui_accept"):

		throw_dice(charge)

		charge = 0.0

func throw_dice(force):

	var dice = dice_scene.instantiate()

	add_child(dice)

	dice.global_position = Vector3(0,10,0)

	var dir = Vector3(
		randf_range(-0.2,0.2),
		-1,
		randf_range(-0.2,0.2)
	).normalized()

	dice.apply_impulse(dir * force)

	dice.apply_torque_impulse(Vector3(
		randf_range(-10,10),
		randf_range(-10,10),
		randf_range(-10,10)
	))
