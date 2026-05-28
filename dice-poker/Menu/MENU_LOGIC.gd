extends CanvasLayer

@onready var menu = $MENU
@onready var settings = $SETTINGS

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button

@export var return_button: Button

func _ready():
	show_menu()
	
	settings_button.pressed.connect(_on_settings_pressed)
	return_button.pressed.connect(_on_return_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

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
