extends Node2D

# dict of MapObjects
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
var graph := {}
var reversed_graph := {}
var roots_dict := {}
var bases_count = 0

signal ended(win)


func _ready():
	AudioManager.set_music("res://Assets/Audio/MatchSound.ogg")


func built(coords, user_id = 0):
	var cell = $figures.get_cellv(coords)
	if cell in range(22, 26):
		$figures.set_cellv(coords, cell + 5*user_id - 21)


func get_centered(coords):
	if get_mushroom(coords) is Base:
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
		
		assert(get_mushroom(coords) is Base)

	return coords


func can_be_built(origin: Vector2, coords: Vector2, gems: int, user_id = 0):
	if not (objs.has(origin) and is_enough_gems(1, gems, Global.BUILD) and can_build_roots(origin, coords)):
		return false

	for i in objs.keys():
		if i == coords: return false
		if objs[i].user_id != user_id: continue
		 
		var mushroom = get_mushroom(i)
		
		#TODO: rewrite via groups
		if not "min_build_radius" in mushroom:
			continue
		var min_d = mushroom.min_build_radius
		var max_d = mushroom.max_build_radius
		var dsq = (i - coords).abs()
		var value = max(dsq.x, dsq.y)

		if min_d > value:
			return false
		if i == origin and value > max_d:
			return false
	return true


func is_enough_gems(class_id: int, gems: int, action):
	if action in [Global.BUILD, Global.E_ATTACK, Global.E_BOMB, Global.E_DEFENDER]:
		return classes[class_id].instance().cost <= gems
	if action == Global.ATTACK:
		return classes[4].instance().attack_price <= gems


func build(coords: Vector2, class_id: int, user_id = 0):
	var mushroom = classes[class_id].instance()
	mushroom.connect("built", self, "built", [coords, user_id])

	objs[coords] = {
		obj = mushroom,
		user_id = user_id,
	}
	if mushroom is Base:
		$figures.set_cellv(coords, class_id + 5*user_id)
	else:
		$figures.set_cellv(coords, class_id + 21)
	
	if mushroom is Base:
		bases_count += 1
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = {
					obj = mushroom,
					user_id = user_id,
				}

	$figures.add_child(mushroom)
	return mushroom


func ruin(coords: Vector2):
	if !objs.has(coords): return

	var mushroom = get_mushroom(coords)
	if mushroom == null: return

	if mushroom is Base:
		coords = get_centered(coords)
		if coords == $Camera2D.BASE_POS:
			emit_signal("ended", false)
		else:
			bases_count -= 1
		if bases_count == 1:
			emit_signal("ended", true)
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs.erase(coords + Vector2(i,j))
	objs.erase(coords)

	$figures.set_cellv(coords, -1)
	$figures.remove_child(mushroom)


func evolve(coords: Vector2, class_id: int):
	if is_not_ready(coords): return null

	var old = objs[coords]
		
	ruin(coords)
	var mushroom = build(coords, class_id, old.user_id)

	if not mushroom is Defender: return mushroom

	var source = reversed_graph[coords]
	if get_mushroom(source) is Defender:
		build_roots(source, coords, 10, true)

	if !graph.has(coords): return mushroom

	for i in graph[coords]:
		if get_mushroom(i) is Defender:
			build_roots(coords, i, 10, true)
	return mushroom


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


func build_roots(s: Vector2, f: Vector2, type_id: int, evolve = false):
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		roots_dict[r] = [s,f]
		$floor.set_cellv(r, type_id)
	
	if type_id == 13 or evolve: return
	
	if graph.has(s):
		graph[s].push_back(f)
	else:
		graph[s] = [f]
	reversed_graph[f] = s


func attack(s: Vector2, f: Vector2):
	if is_not_ready(s): return

	var roots = roots_trajectory(s, f)
	
	for r in roots:
		if objs.has(r):
			cancellate(r)
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


func explode(coords: Vector2):
	if is_not_ready(coords): return false

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
				cancellate(tmp_coords)
				objs.erase(tmp_coords)
			
			if roots_dict.has(tmp_coords):
				eliminate_without_first(roots_dict[tmp_coords][1])
				clear_root_tale(roots_dict[tmp_coords][0], roots_dict[tmp_coords][1])

			$figures.set_cellv(tmp_coords, -1)
			if $floor.get_cellv(tmp_coords) != 12:
				$floor.set_cellv(tmp_coords, 0)
	return true


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


func get_mushroom(coords: Vector2):
	if objs.has(coords):
		return objs[coords].obj
	return null


func is_not_ready(coords: Vector2):
	return not objs.has(coords) or $figures.get_cellv(coords) >= 20
