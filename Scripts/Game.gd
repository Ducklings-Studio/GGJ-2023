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
	set_fogs()
	add_gems(0)
	build(Vector2.RIGHT * 5, 0)
	clean_action()
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _on_HUD_game_started():
	is_blocking = false


func add_gems(amount):
	gems += amount
	$HUD.set_gems(gems)

func set_fogs():
	for i in range(0, 137):
			for j in range(-64, 74):
				if abs(j) <= i && i + abs(j) < 146 && i - j <= 127:
					$fog.set_cellv(Vector2(i, j), 0)

func built(coords):
	var cell = $figures.get_cellv(coords)
	if cell in range(7, 11):
		$figures.set_cellv(coords, cell - 6)


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
				build_roots(selected, coords, 4)
				clean_action()

		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			clean_action()

	if event is InputEventMouseMotion and selected != null and action == BUILD:
		var evpos = get_global_mouse_position() + delta
		var coords = $floor.world_to_map(evpos) - Vector2.ONE
		show_build_options(selected, coords)


func process_action(action_id):
	action = action_id

	if action == E_ATTACK:
		evolve(selected, 4)
	elif action == E_BOMB:
		evolve(selected, 2)
	elif action == E_DEFENDER:
		evolve(selected, 3)
	elif action == ATTACK:
		print_debug("attack")
	elif action == EXPLOSE:
		print_debug("boom")
	else:
		return
	clean_action()


func clean_action():
	selected = null
	action = null
	$HUD.show_options([])
	$tips.clear()


func show_build_options(origin: Vector2, coords: Vector2):
	$tips.clear()
	
	if can_be_built(origin, coords): 
		$tips.set_cellv(coords, 0)
	else:
		$tips.set_cellv(coords, 1)


func can_be_built(origin: Vector2, coords: Vector2):
	var origins = objs.keys()
	for o in origins:
		var mushroom: BasicMushroom = objs[o]
		
		#TODO: rewrite via groups
		if not "min_build_radius" in mushroom:
			continue
		var min_d = mushroom.min_build_radius
		var max_d = mushroom.max_build_radius
		var dsq = (o - coords).abs()
		var value = max(dsq.x, dsq.y)
		print($fog.get_cellv(coords))
		if min_d > value:
			return false
		if o == origin and value > max_d:
			return false
		if !$fog.get_cellv(coords):
			return false
	return true


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
	mushroom.connect("built", self, "built", [coords])

	objs[coords] = mushroom
	$floor.set_cellv(coords, 4)
	
	if class_id in range(1,5):
		$figures.set_cellv(coords, class_id + 6)
	else:
		$figures.set_cellv(coords, class_id)
	for i in range(-6, 7):
			for j in range(-6, 7):
				if abs(i) + abs(j) < 9:
					$fog.set_cellv(coords + Vector2(i,j), -1)
	
	if class_id == 0:
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = mushroom
		for i in range(-8, 9):
			for j in range(-8, 9):
				if abs(i) + abs(j) < 15:
					$fog.set_cellv(coords + Vector2(i,j), -1)

	$figures.add_child(mushroom)


func ruin(coords: Vector2):
	var mushroom = objs[coords]
	if mushroom == null:
		return

	for i in range(-1, 2):
		for j in range(-1, 2):
			objs.erase(coords + Vector2(i,j))

	$figures.set_cellv(coords, -1)
	$figures.remove_child(mushroom)


func evolve(coords: Vector2, class_id: int):
	ruin(coords)
	build(coords, class_id)


func build_roots(s: Vector2, f: Vector2, type_id: int):
	var delta = (f - s).abs()
	delta.y *= -1
	var sx = -1
	var sy = -1
	if s.x < f.x: sx = 1
	if s.y < f.y: sy = 1
	var error = delta.x + delta.y
	
	while true:
		$floor.set_cellv(s, 2)
		if s == f: break
		var e2 = 2*error
		if e2 >= delta.y:
			if s.x == f.x: break
			error += delta.y
			s.x += sx
		if e2 <= delta.x:
			if s.y == f.y: break
			error += delta.x
			s.y += sy
