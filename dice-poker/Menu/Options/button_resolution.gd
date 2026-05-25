extends OptionButton

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready() -> void:

	# Add resolutions to dropdown
	for i in resolutions.size():

		var res = resolutions[i]

		add_item(str(res.x) + "x" + str(res.y))

	# Get current window resolution
	var current_resolution = DisplayServer.window_get_size()

	# Select current resolution in dropdown
	for i in resolutions.size():

		if resolutions[i] == current_resolution:
			select(i)
			break

	# Connect selection signal
	item_selected.connect(_on_resolution_selected)


func _on_resolution_selected(index: int) -> void:

	var selected_resolution = resolutions[index]

	# Apply resolution
	DisplayServer.window_set_size(selected_resolution)

	# Optional: center window
	DisplayServer.window_set_position(
		(DisplayServer.screen_get_size() - selected_resolution) / 2
	)
