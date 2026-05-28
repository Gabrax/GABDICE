extends Node3D

@export var music_player: AudioStreamPlayer3D
var tracks = [
	preload("res://Assets/Music/tavern1.mp3"),
	preload("res://Assets/Music/tavern2.mp3")
]
var current_track := 0

@export var dice_scene: PackedScene
var charge := 0.0
const MAX_FORCE := 0.1
const CHARGE_SPEED := 0.1

@onready var charge_bar = $"HUD/ProgressBar"
@onready var pause_screen = $PAUSE

var is_pause := false

func _ready():
	pause_screen.hide()
	
	music_player.volume_db = -25
	music_player.finished.connect(_on_finished)
	play_current()

func play_current():
	music_player.stream = tracks[current_track]
	music_player.play()

func _on_finished():
	current_track += 1

	if current_track >= tracks.size():
		current_track = 0

	play_current()

func _process(delta):
	
	if Input.is_action_just_pressed("ui_cancel"):
		is_pause = !is_pause

		if is_pause:
			pause_screen.show()
		else:
			pause_screen.hide()
	
	if Input.is_action_pressed("ui_accept"):

		charge += CHARGE_SPEED * delta
		charge = clamp(charge, 0.0, MAX_FORCE)

		# Update UI
		charge_bar.value = (charge / MAX_FORCE) * 100.0


	if Input.is_action_just_released("ui_accept"):

		throw_dice(charge)

		charge = 0.0

		# Reset bar
		charge_bar.value = 0

func throw_dice(force):
	var dice = dice_scene.instantiate()

	add_child(dice)

	dice.global_position = Vector3(0, 10, 0)

	var dir = Vector3(
		randf_range(-0.2, 0.2),
		-1,
		randf_range(-0.2, 0.2)
	).normalized()

	dice.apply_impulse(dir * force)

	dice.apply_torque_impulse(Vector3(
		randf_range(-10, 10),
		randf_range(-10, 10),
		randf_range(-10, 10)
	))
