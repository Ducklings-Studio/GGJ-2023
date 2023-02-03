extends Node2D

export var delta = Vector2(2.5, 2.5) 

var is_blocking = true

var objs = {}
var classes := [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
	preload("res://Scenes/Mushrooms/Bomber.tscn"),
	preload("res://Scenes/Mushrooms/Defender.tscn"),
	preload("res://Scenes/Mushrooms/Attacker.tscn"),
]
var effects := [
	preload("res://Scenes/Explosion.tscn"),
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
var graph := {}
var reversed_graph := {}
var roots_dict := {}

#Base for duelity
const BaseX = -1;
const BaseY = -24;


func _ready():
	set_fogs()
	add_gems(100500)
	
	build(Vector2(BaseX, BaseY), 0)
	
	clean_action()
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func _on_HUD_game_started():
	is_blocking = false


func add_gems(amount):
	gems += amount
	$HUD.set_gems(gems)


const START_X = -70;
const END_X = 70;
const START_Y = -70;
const END_Y = 70;


func set_fogs():
	for i in range(START_X, END_X):
			for j in range(START_Y, END_Y):
				$fog.set_cellv(Vector2(i, j), 0)


func built(coords):
	var cell = $figures.get_cellv(coords)
	if cell in range(7, 11):
		$figures.set_cellv(coords, cell - 6)


func get_centered(coords):
	assert (objs.has(coords))

	if objs[coords] is Base:
		if objs.has(coords + Vector2.DOWN):
			if !objs.has(coords + Vector2.UP):
				coords += Vector2.DOWN
		else:
			coords += Vector2.UP

		if objs.has(coords + Vector2.RIGHT):
			if !objs.has(coords + Vector2.LEFT):
				coords += Vector2.RIGHT
		else:
			coords += Vector2.LEFT
		
		assert(objs.has(coords) and objs[coords] is Base)

	return coords


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
				selected = get_centered(coords)
				$HUD.show_options(objs[selected].abilities)
				return

			if action == BUILD and can_be_built(selected, coords):
				build(coords, 1)
				build_roots(selected, coords, 2)
				if graph.has(selected):
					graph[selected].push_back(coords)
				else:
					graph[selected] = [coords]
				reversed_graph[coords] = selected
				clean_action()
			elif action == ATTACK and is_enough_gems(-1) and can_attack(selected, coords):
				attack(selected, coords)
				clean_action()

		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			clean_action()

	if event is InputEventMouseMotion and selected != null:
		var evpos = get_global_mouse_position() + delta
		var coords = $floor.world_to_map(evpos)
		if action == BUILD:
			show_build_options(selected, coords)
		elif action == ATTACK:
			show_build_options(selected, coords, true)


func process_action(action_id):
	action = action_id

	if action == E_ATTACK:
		if is_enough_gems(4):
			evolve(selected, 4)
	elif action == E_BOMB:
		if is_enough_gems(2):
			evolve(selected, 2)
	elif action == E_DEFENDER:
		if is_enough_gems(3):
			evolve(selected, 3)
	elif action == EXPLOSE:
		explose(selected)
	else:
		return
	clean_action()


func clean_action():
	selected = null
	action = null
	$HUD.show_options([])
	$tips.clear()


func show_build_options(origin: Vector2, coords: Vector2, is_attack = false):
	$tips.clear()
	coords -= Vector2.ONE
	
	if is_attack:
		$tips.set_cellv(coords, 6)
		return

	if can_be_built(origin, coords + Vector2.ONE): 
		$tips.set_cellv(coords, 0)
	else:
		$tips.set_cellv(coords, 1)


func can_be_built(origin: Vector2, coords: Vector2):
	if not (is_enough_gems(1) and can_build_roots(origin, coords)):
		return false

	var origins = objs.keys()
	for o in origins:
		var mushroom = objs[o]
		
		#TODO: rewrite via groups
		if not "min_build_radius" in mushroom:
			continue
		var min_d = mushroom.min_build_radius
		var max_d = mushroom.max_build_radius
		var dsq = (o - coords).abs()
		var value = max(dsq.x, dsq.y)

		if min_d > value:
			return false
		if o == origin and value > max_d:
			return false
		if !$fog.get_cellv(coords):
			return false
	return true


func is_enough_gems(class_id: int):
	if action in [BUILD, E_ATTACK, E_BOMB, E_DEFENDER]:
		return classes[class_id].instance().cost <= gems
	if action == ATTACK:
		return classes[4].instance().attack_price <= gems


#Simple mushroom fog review
const X_FOG_START = -7;
const X_FOG_END = 7;
const Y_FOG_START = -7;
const Y_FOG_END = 7;

#Base mushroom fog review 
const X_FOG_START_BASE = -12;
const X_FOG_END_BASE = 12;
const Y_FOG_START_BASE = -12;
const Y_FOG_END_BASE = 12;


func removeFog(class_id: int, coords: Vector2, 
				xStart: int, xEnd: int, 
				yStart: int, yEnd: int):
	for i in range(xStart, xEnd): 
		for j in range(yStart, yEnd):
			$fog.set_cellv(coords + Vector2(i,j), -1);


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
	mushroom.connect("built", self, "built", [coords])
	
	if class_id != 0:
		add_gems(-mushroom.cost)
	
	objs[coords] = mushroom
	
	if class_id in range(1,5):
		$figures.set_cellv(coords, class_id + 6)
	else:
		$figures.set_cellv(coords, class_id)
		
	removeFog(class_id, coords,
			X_FOG_START, X_FOG_END, 
			Y_FOG_START, Y_FOG_END);
	
	if class_id == 0:
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = mushroom
		removeFog(class_id, coords,
				X_FOG_START_BASE, X_FOG_END_BASE, 
				Y_FOG_START_BASE, Y_FOG_END_BASE);

	$figures.add_child(mushroom)


func ruin(coords: Vector2):
	if !objs.has(coords):
		return
	var mushroom = objs[coords]
	if mushroom == null: return

	for i in range(-1, 2):
		for j in range(-1, 2):
			objs.erase(coords + Vector2(i,j))
			#graph.erase(coords + Vector2(i,j))
			#reversed_graph.erase(coords + Vector2(i,j))

	$figures.set_cellv(coords, -1)
	$figures.remove_child(mushroom)


func evolve(coords: Vector2, class_id: int):
	ruin(coords)
	build(coords, class_id)

	if class_id != 3:
		return
	var source = reversed_graph[coords]
	if objs.has(source) and objs[source] is Defender:
		build_roots(source, coords, 10)
	if !graph.has(coords):
		return
	for i in graph[coords]:
		if objs.has(i) and objs[i] is Defender:
			build_roots(coords, i, 10)


func roots_trajectory(s: Vector2, f: Vector2):
	var result := []

	var delta = (f - s).abs()
	delta.y *= -1
	var sx = -1
	var sy = -1
	if s.x < f.x: sx = 1
	if s.y < f.y: sy = 1
	var error = delta.x + delta.y
	
	while true:
		result.push_back(s)
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
	
	result.pop_front()
	return result


func clear_roots(s: Vector2, f: Vector2):
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		roots_dict.erase(r)
		$floor.set_cellv(r, 0)


func build_roots(s: Vector2, f: Vector2, type_id: int):
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		roots_dict[r] = [s,f]
		$floor.set_cellv(r, type_id)


func attack(s: Vector2, f: Vector2):
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		if roots_dict.has(r) and roots_dict[r][1] != s:
			eliminate_without_first(roots_dict[r][1])
			clear_root_tale(roots_dict[r][0], roots_dict[r][1])
	
	if reversed_graph.has(s):
		build_roots(s, f, 13)
	else:
		clear_roots(s, f)


func can_attack(s: Vector2, f: Vector2):
	if s == null or f == null:
		return false
	
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		if is_not_attackable(r):
			return false 
	
	return true


func can_build_roots(s: Vector2, f: Vector2):
	if s == null or f == null:
		return false
	
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		if not is_ground(r):
			return false 
	
	return true


func explose(coords: Vector2):
	var effect = effects[0].instance()
	effect.position = $figures.map_to_world(coords)
	$figures.add_child(effect)
	
	var timer = Timer.new()
	timer.wait_time = 1
	timer.connect("timeout", self, "explosion_ended", [timer, effect])
	add_child(timer)
	timer.start()
	
	for i in range(-2, 3):
		for j in range(-2, 3):
			var tmp_coords = coords + Vector2(i,j)
			if objs.has(tmp_coords):
				objs.erase(tmp_coords)
			attack(coords, coords + Vector2(i,j))
			
			$figures.set_cellv(tmp_coords, -1)
			if $floor.get_cellv(tmp_coords) != 12:
				$floor.set_cellv(tmp_coords, 0)


func explosion_ended(timer: Timer, effect):
	timer.stop()
	remove_child(timer)
	$figures.remove_child(effect)


func is_not_attackable(coords: Vector2):
	return $floor.get_cellv(coords) in [5,10,12]


func is_ground(coords: Vector2):
	return $floor.get_cellv(coords) in [0,1,3,4,6,7,8,9,11,13]


func eliminate_without_first(m_coords: Vector2):
	if !graph.has(m_coords):
		reversed_graph.erase(m_coords)
		return
	for c in graph[m_coords]:
		clear_roots(m_coords, c)
		cancellate(c)
	reversed_graph.erase(m_coords)
	graph.erase(m_coords)


func cancellate(m_coords: Vector2):
	if !graph.has(m_coords):
		reversed_graph.erase(m_coords)
		ruin(m_coords)
		return
	for c in graph[m_coords]:
		clear_roots(m_coords, c)
		cancellate(c)
	ruin(m_coords)
	reversed_graph.erase(m_coords)
	graph.erase(m_coords)


func clear_root_tale(s: Vector2, f: Vector2):
	clear_roots(s, f)
	ruin(f)
	if reversed_graph.has(f):
		reversed_graph.erase(f)
	if graph.has(s) and graph[s].has(f):
		graph[s].erase(f)
