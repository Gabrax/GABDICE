extends Node3D

# =========================
# MUSIC
# =========================

@export var music_player: AudioStreamPlayer3D

var tracks = [
	preload("res://Assets/Music/tavern1.mp3"),
	preload("res://Assets/Music/tavern2.mp3")
]

var current_track := 0

# =========================
# DICE
# =========================

@export var dice_scene: PackedScene

var charge := 0.0

const MAX_FORCE := 0.1
const CHARGE_SPEED := 0.1

# =========================
# UI
# =========================

@onready var hud = $HUD
@onready var charge_bar = $HUD/ProgressBar

@onready var menu_canvas = $MENU
@onready var menu = $MENU/MENU
@onready var settings = $MENU/SETTINGS

@onready var pause_screen = $PAUSE

# =========================
# MAIN MENU BUTTONS
# =========================

@onready var play_button = $MENU/MENU/play_button
@onready var settings_button = $MENU/MENU/settings_button
@onready var exit_button = $MENU/MENU/exit_button

# =========================
# SETTINGS BUTTONS
# =========================

@onready var return_button = $MENU/SETTINGS/return_button

# =========================
# PAUSE BUTTONS
# =========================

@onready var resume_button = $PAUSE/MENU/play_button
@onready var disconnect_button = $PAUSE/MENU/exit_button
@onready var pause_settings_button = $PAUSE/MENU/settings_button

# =========================
# STATES
# =========================

var is_game := false
var is_pause := false
var settings_from_pause := false

# =========================
# READY
# =========================

func _ready():

	# UI
	hud.hide()

	settings.hide()
	pause_screen.hide()

	menu.show()

	# Main menu buttons
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Settings buttons
	return_button.pressed.connect(_on_return_pressed)

	# Pause buttons
	resume_button.pressed.connect(_on_resume_pressed)

	disconnect_button.pressed.connect(
		_on_disconnect_pressed
	)

	pause_settings_button.pressed.connect(
		_on_pause_settings_pressed
	)

	# Music
	music_player.volume_db = -25

	music_player.finished.connect(_on_finished)

	play_current()

# =========================
# MUSIC
# =========================

func play_current():

	music_player.stream = tracks[current_track]

	music_player.play()

func _on_finished():

	current_track += 1

	if current_track >= tracks.size():

		current_track = 0

	play_current()

# =========================
# PROCESS
# =========================

func _process(delta):

	# Pause toggle
	if is_game and Input.is_action_just_pressed("ui_cancel"):

		if settings.visible:
			return

		is_pause = !is_pause

		if is_pause:

			show_pause()

		else:

			hide_pause()

	# Dice charging
	if is_game and not is_pause:

		if Input.is_action_pressed("ui_accept"):

			charge += CHARGE_SPEED * delta

			charge = clamp(
				charge,
				0.0,
				MAX_FORCE
			)

			charge_bar.value = (
				charge / MAX_FORCE
			) * 100.0

		if Input.is_action_just_released("ui_accept"):

			throw_dice(charge)

			charge = 0.0

			charge_bar.value = 0

# =========================
# MAIN MENU
# =========================

func _on_play_pressed():

	menu.hide()

	settings.hide()

	hud.show()

	is_game = true

func _on_exit_pressed():

	get_tree().quit()

func _on_settings_pressed():

	settings_from_pause = false

	show_settings()

# =========================
# PAUSE
# =========================

func _on_resume_pressed():

	hide_pause()

func _on_disconnect_pressed():

	hide_pause()

	is_game = false

	hud.hide()

	menu.show()

func _on_pause_settings_pressed():

	settings_from_pause = true

	show_settings()

func show_pause():

	is_pause = true

	pause_screen.show()

	get_tree().paused = true

func hide_pause():

	is_pause = false

	pause_screen.hide()

	get_tree().paused = false

# =========================
# SETTINGS
# =========================

func _on_return_pressed():

	settings.hide()

	if settings_from_pause:

		pause_screen.show()

	else:

		menu.show()

func show_settings():

	menu.hide()

	pause_screen.hide()

	settings.show()

# =========================
# DICE
# =========================

func throw_dice(force):

	var dice = dice_scene.instantiate()

	add_child(dice)

	dice.global_position = Vector3(
		0,
		10,
		0
	)

	var dir = Vector3(
		randf_range(-0.2, 0.2),
		-1,
		randf_range(-0.2, 0.2)
	).normalized()

	dice.apply_impulse(dir * force)

	dice.apply_torque_impulse(
		Vector3(
			randf_range(-10, 10),
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
	)
