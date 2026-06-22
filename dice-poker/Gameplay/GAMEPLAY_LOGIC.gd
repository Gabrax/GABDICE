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

@onready var hud = $MENU/HUD
@onready var charge_bar = $MENU/HUD/ProgressBar

@onready var menu_canvas = $MENU
@onready var menu = $MENU/MENU
@onready var settings = $MENU/SETTINGS

@onready var pause_screen = $MENU/PAUSE

@onready var join_button = $MENU/MENU/join_button
@onready var host_button = $MENU/MENU/host_button
@onready var settings_button = $MENU/MENU/settings_button
@onready var exit_button = $MENU/MENU/exit_button

@onready var return_button = $MENU/SETTINGS/return_button

@onready var resume_button = $MENU/PAUSE/resume_button
@onready var disconnect_button = $MENU/PAUSE/exit_button
@onready var pause_settings_button = $MENU/PAUSE/settings_button

var is_game := false
var is_pause := false
var settings_from_pause := false

func _ready():
	hud.hide()

	settings.hide()
	pause_screen.hide()

	menu.show()

	# Main menu buttons
	join_button.pressed.connect(_on_join_pressed)
	host_button.pressed.connect(_on_host_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# Settings buttons
	return_button.pressed.connect(_on_return_pressed)

	# Pause buttons
	resume_button.pressed.connect(_on_resume_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_pressed)

	# Music
	music_player.volume_db = -25

	music_player.finished.connect(_on_finished)

	play_current()

const PORT = 7777

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(PORT)

	if error != OK:
		print("Couldn't start server")
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	var upnp = UPNP.new()

	var result = upnp.discover()
	print("UPnP Discover result:", result)

	if result == UPNP.UPNP_RESULT_SUCCESS:
		var gateway = upnp.get_gateway()
		print("UPnP Gateway:", gateway)

		if gateway and gateway.is_valid_gateway():
			upnp.add_port_mapping(PORT, PORT, ProjectSettings.get_setting("application/config/name"), "UDP")

			var public_ip = upnp.query_external_address()

			print("UPnP success!")
			print("Public IP:", public_ip)
			print("Port:", PORT)
			
			#var public_ip = upnp.query_external_address()
			#$IPAddressLabel.text = public_ip
			
		else:
			print("Invalid gateway")
	else:
		print("UPnP not available")

	print("Server started")

func _on_peer_connected(id):
	print("Client connected:", id)

func _on_join_pressed():
	menu.hide()
	settings.hide()
	
	var peer = ENetMultiplayerPeer.new()

	var error = peer.create_client("PUBLIC_IP_HOSTA", PORT)

	if error != OK:
		print("Couldn't connect")
		return

	multiplayer.multiplayer_peer = peer

	is_game = true

	print("Connecting...")

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

			charge = clamp(charge, 0.0,MAX_FORCE)

			charge_bar.value = (charge / MAX_FORCE) * 100.0

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

	dice.global_position = Vector3(0,10,0)

	var dir = Vector3(randf_range(-0.2, 0.2),-1,randf_range(-0.2, 0.2)).normalized()

	dice.apply_impulse(dir * force)

	dice.apply_torque_impulse(Vector3(randf_range(-10, 10),randf_range(-10, 10),randf_range(-10, 10)))
