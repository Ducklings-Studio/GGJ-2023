extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true

var objs = {}
var classes = [
	preload("res://Scenes/Mushrooms/Standart.tscn"),
]
var gems = 0


func _ready():
	assert (len(classes) > 0)
	
	add_gems(0)
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _on_HUD_game_started():
	is_blocking = false


func add_gems(amount):
	gems += amount
	$HUD.set_gems(gems)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $floor.world_to_map(evpos)

			if objs.has(coords):
				print_debug("already here")
				return

			build(coords, evpos, 0)


func build(coords: Vector2, evpos: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	mushroom.position = evpos #mb redundant
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")

	objs[coords] = mushroom
	$floor.set_cellv(coords, 4)
	$figures.set_cellv(coords, 1)
	$figures.add_child(mushroom)
