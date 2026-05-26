extends Control

@onready var menu = get_node("/root/MainScene/UI/MENU")
@onready var menu_options = get_node("/root/MainScene/UI/MENU_OPTIONS")

@onready var menu_play_button = get_node("/root/MainScene/UI/MENU/VBoxContainer/button_play")
@onready var menu_options_button = get_node("/root/MainScene/UI/MENU/VBoxContainer/button_options")
@onready var menu_quit_button = get_node("/root/MainScene/UI/MENU/VBoxContainer/button_quit")

@onready var options_return_button = get_node("/root/MainScene/UI/MENU_OPTIONS/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/button_return")


func _ready() -> void:

	menu.show()
	menu_options.hide()

	menu_play_button.pressed.connect(_on_play_pressed)
	menu_options_button.pressed.connect(_on_options_pressed)
	menu_quit_button.pressed.connect(_on_quit_pressed)

	options_return_button.pressed.connect(_on_return_pressed)


func _on_play_pressed() -> void:

	menu.hide()
	menu_options.hide()


func _on_options_pressed() -> void:

	menu.hide()
	menu_options.show()


func _on_quit_pressed() -> void:

	get_tree().quit()


func _on_return_pressed() -> void:

	menu_options.hide()
	menu.show()
