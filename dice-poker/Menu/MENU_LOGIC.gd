extends CanvasLayer

@onready var menu = $MENU
@onready var settings = $SETTINGS

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button

@export var return_button: Button

@onready var hud = $"../HUD"

@onready var pause = $"../PAUSE"

var is_menu := false
var is_game := false

func _ready():
	show_menu()
	is_menu = true
	
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	return_button.pressed.connect(_on_return_pressed)
	
	hud.hide()

func _on_play_pressed():
	menu.hide()
	hud.show()
	is_game = true

func _on_exit_pressed():
	get_tree().quit()

func _on_settings_pressed():
	show_settings()

func _on_return_pressed():
	show_menu()

func show_settings():
	menu.hide()
	settings.show()

func show_menu():
	settings.hide()
	menu.show()
