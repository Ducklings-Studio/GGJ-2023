extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true

var objs = {}
var classes = [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
	preload("res://Scenes/Mushrooms/Bomber.tscn"),
	preload("res://Scenes/Mushrooms/Defender.tscn"),
	preload("res://Scenes/Mushrooms/Attacker.tscn"),
]
enum {
	BUILD, 
	E_ATTACK, 
	E_BOMB, 
	E_DEFENDER, 
	ATTACK, 
	EXPLOSE,
}
var gems = 0


func _ready():
	add_gems(0)
	build(Vector2.RIGHT * 5, 0)
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _on_HUD_game_started():
	is_blocking = false


func add_gems(amount):
	gems += amount
	$HUD.set_gems(gems)


var selected
var action

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if !event.is_pressed():
			return

		if InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = $floor.world_to_map(evpos)

			if objs.has(coords):
				#TOOD: get cental coords
				print_debug("already here", objs[coords])
				selected = coords
				$HUD.show_options(objs[coords].abilities)
				return

			if selected != null and action == BUILD and can_be_built(selected, coords):
				build(coords, 1)

		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			selected = null
			action = null
			$HUD.show_options([])
			$tips.clear()

	if event is InputEventMouseMotion and selected != null and action == BUILD:
		var evpos = get_global_mouse_position() + delta
		var coords = $floor.world_to_map(evpos) - Vector2.ONE
		show_build_options(selected, coords)


func process_action(action_id):
	action = action_id

	if action == E_ATTACK:
		print_debug("transform to attacker")
	elif action == E_BOMB:
		print_debug("transform to bomb")
	elif action == E_DEFENDER:
		print_debug("transform to defender")
	elif action == ATTACK:
		print_debug("attack")
	elif action == EXPLOSE:
		print_debug("boom")


func show_build_options(origin: Vector2, coords: Vector2):
	$tips.clear()
	
	if can_be_built(origin, coords): 
		$tips.set_cellv(coords, 0)
	else:
		$tips.set_cellv(coords, 1)


func can_be_built(origin: Vector2, coords: Vector2):
	var origins = objs.keys()
	for o in origins:
		var mushroom = objs[o]
		
		var min_d = mushroom.min_build_radius
		var max_d = mushroom.max_build_radius
		var dsq = (o - coords).abs()
		var value = max(dsq.x, dsq.y)
		
		if min_d > value:
			return false
		if o == origin and value > max_d:
			return false
	return true


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
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
