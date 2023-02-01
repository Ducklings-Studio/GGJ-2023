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


var selected

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if !event.is_pressed():
			return
		if InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $floor.world_to_map(evpos) - Vector2.ONE

			if objs.has(coords):
				#TOOD: get cental coords
				print_debug("already here", objs[coords])
				selected = coords
				$HUD.show_options([1,2,3,4])
				return

			if selected != null and can_be_built(selected, coords):
				build(coords, 1)

		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			selected = null
			$tips.clear()

	if event is InputEventMouseMotion and selected != null:
		var evpos = get_global_mouse_position() + delta
		var coords = $floor.world_to_map(evpos) - Vector2.ONE
		show_build_options(selected, coords)


func show_build_options(origin: Vector2, coords: Vector2):
	$tips.clear()
	
	if can_be_built(origin, coords): 
		$tips.set_cellv(coords, 0)
	else:
		$tips.set_cellv(coords, 1)


func can_be_built(origin: Vector2, coords: Vector2):
	if origin == null:
		return false
	var mushroom = objs[origin]

	var max_sq = mushroom.max_build_radius*mushroom.max_build_radius
	var min_sq = mushroom.min_build_radius*mushroom.min_build_radius
	var dsq = origin.distance_squared_to(coords)

	return min_sq <= dsq and dsq <= max_sq


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	#mushroom.position = evpos #mb redundant
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")

	objs[coords] = mushroom
	$floor.set_cellv(coords, 4)
	$figures.set_cellv(coords, class_id)

	if class_id == 0:
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = mushroom

	$figures.add_child(mushroom)
