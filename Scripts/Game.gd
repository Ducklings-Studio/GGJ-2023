extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true

func _ready():
	AudioManager.set_music("res://Assets/Audio/MatchSound1.ogg")


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $floor.world_to_map(evpos)
			$floor.set_cellv(coords, 4)
			$figures.set_cellv(coords, 1)
