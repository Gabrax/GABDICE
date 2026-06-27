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

@onready var dice_container := $GameMap/DiceContainer

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

@onready var host_screen        := $UI/HOST
@onready var host_input_nick    := $UI/HOST/LineEdit
@onready var host_return_button := $UI/HOST/exit_button
@onready var host_init_button   := $UI/HOST/init_button

@onready var join_screen     := $UI/JOIN
@onready var join_input      := $UI/JOIN/LineEdit
@onready var join_input_nick := $UI/JOIN/LineEdit2
@onready var join_connect    := $UI/JOIN/connect_button
@onready var join_return     := $UI/JOIN/return_button
@onready var join_status     := $UI/JOIN/Label

@onready var game_lobby              := $UI/LOBBY
@onready var game_lobby_user1        := $UI/LOBBY/Label
@onready var game_lobby_user2        := $UI/LOBBY/Label2
@onready var game_lobby_user3        := $UI/LOBBY/Label3
@onready var game_lobby_user4        := $UI/LOBBY/Label4
@onready var game_lobby_user5        := $UI/LOBBY/Label5
@onready var ready_button            := $UI/LOBBY/ready_button
@onready var lobby_disconnect_button := $UI/LOBBY/disconnect_button
@onready var countdown               := $UI/LOBBY/countdown

@onready var hud              := $UI/HUD
@onready var charge_bar       := $UI/HUD/ProgressBar
@onready var turn_label1      := $UI/HUD/Player1
@onready var turn_label2      := $UI/HUD/Player2
@onready var turn_label3      := $UI/HUD/Player3
@onready var turn_label4      := $UI/HUD/Player4
@onready var turn_label5      := $UI/HUD/Player5
@onready var pass_turn_button := $UI/HUD/PassTurn

var players := {}
var player_name = ""
var ready_players := {}

var is_game  := false 
var is_pause := false
var settings_from_pause := false

var game_started := false

var player_order := []
var current_turn := 0

var dice_thrown := {}

var countdown_active := false
var countdown_time := 5

func _ready():
	hud.hide()
	join_screen.hide()
	settings.hide()
	pause_screen.hide()
	game_lobby.hide()
	host_screen.hide()
	pass_turn_button.hide()
	menu.show()

	#if !multiplayer.peer_connected.is_connected(_on_peer_connected):
		#multiplayer.peer_connected.connect(_on_peer_connected)

	if !multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if !multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	if !multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)

	if !multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Main menu
	join_button.pressed.connect(_on_join_pressed)
	host_button.pressed.connect(_on_host_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# Settings
	return_button.pressed.connect(_settings_on_return_pressed)

	# Pause
	resume_button.pressed.connect(_on_resume_pressed)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	pause_settings_button.pressed.connect(_on_pause_settings_pressed)
	
	# Host
	host_init_button.pressed.connect(_on_host_init_server)
	host_return_button.pressed.connect(_on_host_return)
	
	# Join
	join_connect.pressed.connect(_on_connect_pressed)
	join_return.pressed.connect(_join_on_return_pressed)

	# lobby
	ready_button.pressed.connect(_on_ready_pressed)
	lobby_disconnect_button.pressed.connect(_on_disconnect_pressed)

	# Game
	pass_turn_button.pressed.connect(_on_pass_turn_pressed)

	# Music
	music_player.volume_db = -25
	music_player.finished.connect(_on_finished)
	play_current()

func _on_game_ready():
	hud.show()

func _on_pass_turn_pressed():
	if !is_my_turn(): return
	pass_turn_button.hide()
	rpc_id(1, "next_turn")

@rpc("any_peer","call_local","reliable")
func next_turn():
	if !multiplayer.is_server():
		return

	clear_dice.rpc()

	var previous = player_order[current_turn]
	dice_thrown[previous] = 0

	current_turn += 1

	if current_turn >= player_order.size():
		current_turn = 0

	var next = player_order[current_turn]
	dice_thrown[next] = 0

	rpc("sync_dice_thrown", dice_thrown)
	rpc("sync_turn", current_turn)

@rpc("authority","call_local","reliable")
func clear_dice():
	for dice in dice_container.get_children(): dice.queue_free()

@rpc("call_local","reliable")
func sync_turn(turn):
	current_turn = turn
	update_turn_ui()
	update_pass_turn_button()

func _on_host_init_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)

	if error != OK: return

	multiplayer.multiplayer_peer = peer
	
	player_name = host_input_nick.text
	if player_name.is_empty():
		player_name = "Host"

	var my_id = multiplayer.get_unique_id()
	players[my_id] = {"name": player_name,"ready": false}
	
	host_screen.hide()
	show_lobby()

	is_game = true

func _on_host_return():
	hud.hide()
	join_screen.hide()
	settings.hide()
	pause_screen.hide()
	game_lobby.hide()
	host_screen.hide()
	menu.show()

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
	if !multiplayer_active(): return
	
	if join_status.text.begins_with("Connecting"): connect_timer += delta

	if countdown_active:
		countdown_time -= delta

		if countdown_time <= 0:
			countdown_active = false
			begin_game()

	if connect_timer > 3.0:
		cleanup_game()
		join_status.text = "Connection timed out"

		connect_timer = 0.0
	
	# Pause toggle
	if is_game and Input.is_action_just_pressed("ui_cancel"):
		if settings.visible:return

		is_pause = !is_pause

		if is_pause:show_pause()
		else: hide_pause()

	# Dice charging
	if is_game and not is_pause:
		charge_dice(delta)

# =========================
# MAIN MENU
# =========================

func _on_host_pressed():
	hud.hide()
	join_screen.hide()
	settings.hide()
	pause_screen.hide()
	game_lobby.hide()
	menu.hide()
	
	host_screen.show()

func _on_connected_to_server():
	connect_timer = 0.0
	join_status.text = "Connected!"

	show_lobby()

	rpc_id(1,"register_player",multiplayer.get_unique_id(),player_name)

	is_game = true

@rpc("any_peer","reliable")
func register_player(id, name):

	players[id] = {"name": name,"ready": false}

	update_lobby()

	rpc("sync_players", players)
	
@rpc("call_local", "reliable")
func sync_players(new_players):
	players = new_players
	update_lobby()
	
func _on_peer_disconnected(id):
	players.erase(id)
	player_order.erase(id)
	dice_thrown.erase(id)
	
	if player_order.size() > 0:
		current_turn %= player_order.size()
		rpc("sync_turn", current_turn)

	update_lobby()
	rpc("sync_players", players)
	
func show_lobby():
	menu.hide()
	join_screen.hide()
	hud.hide()

	game_lobby.show()
	countdown.text = "Waiting for players readyness..."

	update_lobby()
	
func update_lobby():
	var labels = [
		game_lobby_user1,
		game_lobby_user2,
		game_lobby_user3,
		game_lobby_user4,
		game_lobby_user5
	]

	for l in labels:
		l.text = ""

	var index = 0

	for id in players.keys():
		var p = players[id]
		var txt = p["name"]
		
		if id == 1:
			txt += " (HOST)"
		if p["ready"]:
			txt += " [READY]"
		else:
			txt += " [NOT READY]"

		if index < labels.size():
			labels[index].text = txt
			
		index += 1
		
func _on_ready_pressed():
	var my_id = multiplayer.get_unique_id()

	if multiplayer.is_server():
		toggle_ready(my_id)
	else:
		rpc_id(1, "set_ready", my_id)

func toggle_ready(id):
	if players.has(id):
		players[id]["ready"] = !players[id]["ready"]

	update_lobby()

	if multiplayer.is_server():
		rpc("sync_players", players)
		
	check_all_ready()
	
func check_all_ready():

	if !multiplayer.is_server() or countdown_active or game_started:
		return

	if players.size() < 2:
		countdown.text = "At least 2 Players have to be ready"
		return

	for p in players.values():
		if !p["ready"]:
			countdown_active = false
			rpc("show_waiting")
			return

	if !countdown_active:
		start_countdown()

@rpc("call_local","reliable")
func show_waiting():
	countdown.text = "Waiting for players readyness..."

func start_countdown():
	countdown_active = true

	countdown_time = 5

	rpc("show_countdown", countdown_time)

	while countdown_time > 0:
		await get_tree().create_timer(1.0).timeout

		if !countdown_active: 
			return

			countdown_time -= 1

			rpc("show_countdown", countdown_time)

	if !countdown_active:
		return

	begin_game()

@rpc("call_local","reliable")
func show_countdown(value):
	if value > 0:
		countdown.text = "Game starts in %d" % value
	else:
		countdown.text = "START!"

func begin_game():
	countdown_active = false
	game_started = true

	player_order.clear()

	for id in players.keys():
		player_order.append(id)

	player_order.sort()

	current_turn = 0

	dice_thrown.clear()

	for id in players.keys():
		dice_thrown[id] = 0

	rpc("start_game_rpc", player_order)

@rpc("call_local","reliable")
func start_game_rpc(order):

	player_order = order
	game_started = true

	dice_thrown.clear()

	for id in player_order:
		dice_thrown[id] = 0

	countdown.text = ""
	game_lobby.hide()
	hud.show()

	update_turn_ui()
	update_pass_turn_button()

func update_turn_ui():
	var labels = [
		turn_label1,
		turn_label2,
		turn_label3,
		turn_label4,
		turn_label5
	]

	for l in labels:
		l.text = ""

	for i in range(player_order.size()):
		var id = player_order[i]
		var txt = players[id]["name"]

		if i == current_turn:
			txt += " <-"

		if i < labels.size():
			labels[i].text = txt

func is_my_turn():
	if player_order.is_empty():
		return false

	if current_turn >= player_order.size():
		return false

	return player_order[current_turn] == multiplayer.get_unique_id()

@rpc("any_peer", "reliable")
func set_ready(id):
	toggle_ready(id)

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

func cleanup_game():
	# ===== Multiplayer =====
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = null

	# ===== Stan gry =====
	game_started = false
	is_pause = false
	is_game = false

	current_turn = 0
	charge = 0.0

	# ===== Lobby =====
	players.clear()
	player_order.clear()
	dice_thrown.clear()
	ready_players.clear()

	# ===== Countdown =====
	countdown_active = false
	countdown_time = 5

	# ===== UI =====
	menu.show()
	hud.hide()
	game_lobby.hide()
	host_screen.hide()
	join_screen.hide()
	pause_screen.hide()
	settings.hide()
	pass_turn_button.hide()

	connect_timer = 0.0
	
	charge_bar.value = 0

	join_status.text = ""
	countdown.text = ""

	host_input_nick.text = ""
	join_input.text = ""
	join_input_nick.text = ""

	turn_label1.text = ""
	turn_label2.text = ""
	turn_label3.text = ""
	turn_label4.text = ""
	turn_label5.text = ""

	# ===== Lobby UI =====
	update_lobby()

	# ===== Kostki =====
	for dice in dice_container.get_children():
		dice.queue_free()

	# ===== Kamera =====
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_connect_pressed():
	var ip = join_input.text.strip_edges()

	player_name = join_input_nick.text

	if player_name.is_empty():
		player_name = "Player"

	if ip.is_empty():
		ip = LOCAL_IP

	join_status.text = "Connecting to %s:%d..." % [ip, PORT]

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)

	if error != OK:
		join_status.text = "ENet Error: %s" % error_string(error)
		return

	multiplayer.multiplayer_peer = peer
	
func _on_connection_failed(): cleanup_game()
	
func _on_server_disconnected(): cleanup_game()

func multiplayer_active() -> bool:
	if multiplayer.multiplayer_peer == null: return false

	return multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func _on_connect_success(): is_game = true

func _on_exit_pressed(): get_tree().quit()

func _on_settings_pressed():
	settings_from_pause = false
	show_settings()

func _join_on_return_pressed():
	join_screen.hide()
	menu.show()

# =========================
# PAUSE
# =========================

func _on_resume_pressed(): hide_pause()

func _on_disconnect_pressed(): cleanup_game()

func _on_pause_settings_pressed():
	settings_from_pause = true
	show_settings()

func show_pause():
	is_pause = true
	pause_screen.show()
	#get_tree().paused = true

func hide_pause():
	is_pause = false
	pause_screen.hide()
	#get_tree().paused = false

# =========================
# SETTINGS
# =========================

func show_settings():
	menu.hide()
	pause_screen.hide()
	settings.show()

func _settings_on_return_pressed():
	settings.hide()

	if settings_from_pause: pause_screen.show()
	else: menu.show()

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

@rpc("call_local", "reliable")
func sync_dice_thrown(new_data):
	dice_thrown = new_data.duplicate()
	update_pass_turn_button()

func update_pass_turn_button():
	pass_turn_button.hide()

	if !game_started:
		return

	if !multiplayer.has_multiplayer_peer():
		return

	if !is_my_turn():
		return

	var my_id = multiplayer.get_unique_id()

	if dice_thrown.get(my_id, 0) >= 6:
		pass_turn_button.show()

func throw_dice(force):
	var my_id = multiplayer.get_unique_id()

	if !is_my_turn():
		return

	if dice_thrown[my_id] >= 6:
		return

	if multiplayer.is_server():
		dice_thrown[my_id] += 1
		rpc("sync_dice_thrown", dice_thrown)
		spawn_dice(force)
	else:
		rpc_id(1, "request_throw", force)
		
@rpc("any_peer","reliable")
func request_throw(force):
	if !multiplayer.is_server():
		return

	var sender = multiplayer.get_remote_sender_id()

	if !dice_thrown.has(sender):
		dice_thrown[sender] = 0

	if dice_thrown[sender] >= 6:
		return

	force = clamp(force,0.0,MAX_FORCE)

	dice_thrown[sender] += 1
	rpc("sync_dice_thrown", dice_thrown)
	spawn_dice(force)
	

@rpc("call_local","reliable")
func spawn_dice_rpc(pos, force, dir, torque):
	var dice = dice_scene.instantiate()

	dice.set_multiplayer_authority(1)

	dice_container.add_child(dice, true)

	dice.global_position = pos

	await get_tree().physics_frame

	dice.apply_impulse(dir * force)
	dice.apply_torque_impulse(torque)

func spawn_dice(force):

	var dice_position = Vector3(0, 10, 0)

	await get_tree().physics_frame
	
	if !multiplayer_active(): return

	var dir = Vector3(
		randf_range(-0.2, 0.2),
		-1.0,
		randf_range(-0.2, 0.2)
	).normalized()

	var torque = Vector3(
		randf_range(-10, 10),
		randf_range(-10, 10),
		randf_range(-10, 10)
	)

	rpc(
		"spawn_dice_rpc",
		dice_position,
		force,
		dir,
		torque
	)
