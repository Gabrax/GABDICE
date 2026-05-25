extends AudioStreamPlayer3D

var tracks = [
	preload("res://Music/tavern1.mp3"),
	preload("res://Music/tavern2.mp3")
]

var current_track := 0

func _ready():

	volume_db = -25

	finished.connect(_on_finished)

	play_current()


func play_current():

	stream = tracks[current_track]
	play()


func _on_finished():

	current_track += 1

	if current_track >= tracks.size():
		current_track = 0

	play_current()
