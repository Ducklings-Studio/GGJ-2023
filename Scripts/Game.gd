extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true
var kar = preload("res://Scenes/Mushrooms/Standart.tscn")
var gems = 0


func _ready():
	add_gems(0)
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $floor.world_to_map(evpos)
			$floor.set_cellv(coords, 4)
			$figures.set_cellv(coords, 1)
			var mushroom = kar.instance()
			mushroom.connect("res_mined", self, "add_gems")
			mushroom.position = evpos
			$figures.add_child(mushroom)


func _on_HUD_game_started():
	is_blocking = false


func add_gems(amount):
	print("kar", amount)
	gems += amount
	$HUD.set_gems(gems)
