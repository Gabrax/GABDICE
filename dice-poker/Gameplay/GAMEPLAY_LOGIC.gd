extends Node3D

@export var music_player: AudioStreamPlayer3D
var tracks := [
	preload("res://Assets/Music/tavern1.mp3"),
	preload("res://Assets/Music/tavern2.mp3")
]
var current_track := 0

@export var dice_scene: PackedScene
var charge := 0.0
const MAX_FORCE := 0.1
const CHARGE_SPEED := 0.1

const PORT := 7777
const LOCAL_IP := "127.0.0.1"
var connect_timer := 0.0

@onready var hud        := $UI/HUD
@onready var charge_bar := $UI/HUD/ProgressBar

@onready var menu_canvas     := $UI
@onready var menu            := $UI/MENU
@onready var join_button     := $UI/MENU/join_button
@onready var host_button     := $UI/MENU/host_button
@onready var settings_button := $UI/MENU/settings_button
@onready var exit_button     := $UI/MENU/exit_button

@onready var settings      := $UI/SETTINGS
@onready var return_button := $UI/SETTINGS/return_button

@onready var pause_screen          := $UI/PAUSE
@onready var resume_button         := $UI/PAUSE/resume_button
@onready var pause_settings_button := $UI/PAUSE/settings_button
@onready var disconnect_button     := $UI/PAUSE/exit_button

@onready var join_screen   := $UI/JOIN
@onready var join_input    := $UI/JOIN/LineEdit
@onready var join_connect  := $UI/JOIN/connect_button
@onready var join_return   := $UI/JOIN/return_button
@onready var join_status   := $UI/JOIN/Label

var is_game  := false
var is_pause := false
var settings_from_pause := false

func _ready():
	hud.hide()
	join_screen.hide()
	settings.hide()
	pause_screen.hide()
	menu.show()

	# Main menu buttons
	join_button.pressed.connect(_on_join_pressed)
	host_button.pressed.connect(_on_host_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	#Join
	join_connect.pressed.connect(_on_connect_pressed)
	join_return.pressed.connect(_join_on_return_pressed)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Settings buttons
	return_button.pressed.connect(_settings_on_return_pressed)

	# Pause buttons
	resume_button.pressed.connect(_on_resume_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_pressed)

	# Music
	music_player.volume_db = -25
	music_player.finished.connect(_on_finished)
	play_current()

func _on_game_ready():
	hud.show()
	
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
# GAME
# =========================

func _process(delta):
	if join_status.text.begins_with("Connecting"):
		connect_timer += delta

		if connect_timer > 10.0:
			join_status.text = "Connection timed out"
			connect_timer = 0.0
	
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
		charge_dice(delta)

# =========================
# MAIN MENU
# =========================

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Couldn't start server")
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	print("Server started on localhost:", PORT)
	is_game = true

func _on_peer_connected(id):
	print("Client connected:", id)

func _on_join_pressed():
	menu.hide()
	settings.hide()
	join_screen.show()

	join_status.text = "Enter server IP"

func error_string(err: int) -> String:
	match err:
		OK:
			return "OK"
		ERR_CANT_CREATE:
			return "ERR_CANT_CREATE"
		ERR_CANT_CONNECT:
			return "ERR_CANT_CONNECT"
		ERR_ALREADY_IN_USE:
			return "ERR_ALREADY_IN_USE"
		ERR_UNAVAILABLE:
			return "ERR_UNAVAILABLE"
		ERR_INVALID_PARAMETER:
			return "ERR_INVALID_PARAMETER"
		ERR_TIMEOUT:
			return "ERR_TIMEOUT"
		_:
			return "Unknown Error (%d)" % err

func _on_connect_pressed():
	var ip = join_input.text.strip_edges()

	if ip.is_empty():
		ip = LOCAL_IP

	join_status.text = "Connecting to %s:%d..." % [ip, PORT]

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)

	if error != OK:
		join_status.text = "ENet Error: %s" % error_string(error)
		return

	multiplayer.multiplayer_peer = peer
	
	
func _on_connected_to_server():
	join_status.text = "Connected!"
	is_game = true

	join_screen.hide()
	hud.show()
	
func _on_connection_failed():
	join_status.text = "Connection failed."
	
func _on_server_disconnected():
	join_status.text = "Disconnected from server."

	is_game = false

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	menu.show()
	hud.hide()

func _on_connect_success():
	is_game = true

func _on_exit_pressed():
	get_tree().quit()

func _on_settings_pressed():
	settings_from_pause = false
	show_settings()

func _join_on_return_pressed():
	join_screen.hide()
	menu.show()

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

func show_settings():
	menu.hide()
	pause_screen.hide()
	settings.show()

func _settings_on_return_pressed():
	settings.hide()

	if settings_from_pause:
		pause_screen.show()
	else:
		menu.show()

# =========================
# DICE
# =========================

func charge_dice(delta):
	if Input.is_action_pressed("ui_accept"):
		charge += CHARGE_SPEED * delta
		charge = clamp(charge, 0.0,MAX_FORCE)
		charge_bar.value = (charge / MAX_FORCE) * 100.0

	if Input.is_action_just_released("ui_accept"):
		throw_dice(charge)
		charge = 0.0
		charge_bar.value = 0	

func throw_dice(force):
	var dice = dice_scene.instantiate()
	add_child(dice)
	dice.global_position = Vector3(0,10,0)
	var dir = Vector3(randf_range(-0.2, 0.2),-1,randf_range(-0.2, 0.2)).normalized()
	dice.apply_impulse(dir * force)
	dice.apply_torque_impulse(Vector3(randf_range(-10, 10),randf_range(-10, 10),randf_range(-10, 10)))
