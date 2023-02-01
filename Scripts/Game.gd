extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true

var objs = {}
var classes = [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
]
var gems = 0


func _ready():
	assert (len(classes) > 0)
	
	add_gems(0)
	build(Vector2.RIGHT * 5, 0)
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
				print_debug("already here", objs[coords])
				show_build_options(coords, objs[coords])
				$HUD.show_options([1,2,3,4])
				return

			build(coords, 1)


func show_build_options(coords: Vector2, mushroom: BasicMushroom):
	#check if radius exists and optimise loop
	var max_sq = mushroom.max_build_radius*mushroom.max_build_radius
	var min_sq = mushroom.min_build_radius*mushroom.min_build_radius
	print_debug(max_sq, min_sq)
	for i in range(-mushroom.max_build_radius, mushroom.max_build_radius):
		for j in range(-mushroom.max_build_radius, mushroom.max_build_radius):
			print_debug(i*i + j*j)
			if i*i + j*j <= max_sq and i*i + j*j >= min_sq: 
				$figures.set_cellv(coords+Vector2(i,j), 5)


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	#mushroom.position = evpos #mb redundant
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")

	objs[coords] = mushroom
	$floor.set_cellv(coords, 4)
	if class_id == 0:
		$figures.set_cellv(coords, 2)
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = mushroom
	else:
		$figures.set_cellv(coords, class_id)
	$figures.add_child(mushroom)
