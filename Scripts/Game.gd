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

#Base for duelity
const BaseX = -1;
const BaseY = -24;

func _ready():
	set_fogs()
	add_gems(450)
	
	build(Vector2(BaseX, BaseY), 0)
	build(Vector2(BaseX, -BaseY), 0)
	
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
			elif action == ATTACK and is_enough_gems(-1) and cat_attack(selected, coords):
				build_roots(selected, coords, 13)
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
const X_FOG_START = -6;
const X_FOG_END = 6;
const Y_FOG_START = -6;
const Y_FOG_END = 6;

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
	$floor.set_cellv(coords, 4)
	
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
	var mushroom = objs[coords]
	if mushroom == null: return

	for i in range(-1, 2):
		for j in range(-1, 2):
			objs.erase(coords + Vector2(i,j))

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


func build_roots(s: Vector2, f: Vector2, type_id: int):
	var roots = roots_trajectory(s, f)
	
	for r in roots:
		$floor.set_cellv(r, type_id)


func cat_attack(s: Vector2, f: Vector2):
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
	return $floor.get_cellv(coords) in [0,1,3,4,6,7,8,9,11]


func is_field(coords: Vector2):
	return $floor.get_cellv(coords) != 8 # todo: correct it, change to water (not playground)


####################################################
#                 ####       #######
#                ##  ##        ###
#               ##    ##       ###
#              ##########      ###
#             ##        ##     ###
#            ##          ##  #######
####################################################


func put_mushroom(mushroom: Vector2, coords: Vector2):
	build(coords, 1)
	build_roots(mushroom, coords, 2)
	clean_action()


func distance(one: Vector2, two: Vector2):
	return sqrt((one.x - two.x) * (one.x - two.x) + (one.y - two.y) * (one.y - two.y))


func get_def(mushs):
	for i in range(0, len(mushs)):
		if distance(mushs[i], enemyBase) < 10:
			evolve(mushs[i], 4) # todo: change to def


func bombs_attack(mushs):
	var nearestMush
	var neatestDist
	if len(mushs):
		nearestMush = mushs[0]
		neatestDist = distance(mushs[0], enemyBase)
	else:
		nearestMush = base
		neatestDist = distance(base, enemyBase)
	for i in range(1, len(mushs)):
		if distance(mushs[i], enemyBase) < neatestDist:
			nearestMush = mushs[i]
			neatestDist = distance(mushs[i], enemyBase)
	if neatestDist > 6:
		nearestMush = go_to_enemy(nearestMush, enemyBase)
		nearestMush = go_to_enemy(nearestMush, enemyBase)
	else:
		plant_bomb(nearestMush, enemyBase)


func go_to_enemy(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if distance(Vector2(i, j), base) < 2:
				continue;
			print_debug(mush, Vector2(i, j))
			if can_be_built(mush, Vector2(i, j)): #fix can_be_built, doesn't work, or fix my hands
				print_debug("YES")
				if bestPosition == null:
					bestPosition = Vector2(i, j)
					bestDistance = distance(Vector2(i, j), base)
				else:
					if distance(Vector2(i, j), base) < bestDistance:
						bestPosition = Vector2(i, j)
						bestDistance = distance(Vector2(i, j), base)
	if bestPosition != null:
		put_mushroom(mush, bestPosition)
		mushs.append(bestPosition)
		return bestPosition
	return mush


func plant_bomb(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if distance(Vector2(i, j), base) < 2:
				continue;
			if can_be_built(mush, Vector2(i, j)):
				if bestPosition == null:
					bestPosition = Vector2(i, j)
					bestDistance = distance(Vector2(i, j), base)
				else:
					if distance(Vector2(i, j), base) < bestDistance:
						bestPosition = Vector2(i, j)
						bestDistance = distance(Vector2(i, j), base)
	if bestPosition != null:
		put_mushroom(mush, bestPosition)
		mushs.append(bestPosition)
		evolve(bestPosition, 2)

var base = Vector2(5, 0)
var baseCoords := [Vector2(6, 6), Vector2(6, 3), 
	Vector2(6, 0), Vector2(6, -3), Vector2(3, -6), 
	Vector2(1, -6), Vector2(3, 7), Vector2(0, 6), 
	Vector2(-3, 6), Vector2(-6, 1), Vector2(-6, -2),
	Vector2(-2, -6), Vector2(-5, -6)]
var mushs = [] 
var mushDistMin = 2 
var mushDistMax = 5
var mushNum = 0
var mushMush = 0
var mushsCoords := [Vector2(1, 4), Vector2(4, 0), Vector2(3, -2),
	Vector2(0, -3), Vector2(-3, -3), Vector2(-3, 0), Vector2(-8, -3)]
var enemyMush = []
var enemyBase = Vector2(25, -5)
var spawnPoint = true
var afterStop = 3
var defMushs = false
var defCounter = 100
var isAttack = false


func _on_Timer_timeout():
	return
	var nowPoint = len(mushs)
	while nowPoint == len(mushs) && spawnPoint:
		if mushNum < len(baseCoords) && !mushMush && is_field(base+baseCoords[mushNum]):
			put_mushroom(base, base+baseCoords[mushNum])
			mushs.append(base+baseCoords[mushNum])
		elif mushMush && mushNum < len(mushsCoords) && is_field(mushs[mushMush - 1]+mushsCoords[mushNum]):
				if can_be_built(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum]):
					put_mushroom(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum])
					mushs.append(mushs[mushMush - 1]+mushsCoords[mushNum])
					if distance(mushs[mushMush - 1]+mushsCoords[mushNum], enemyBase) < 10:
						afterStop -= 1
					if afterStop == 0:
						spawnPoint = false
					elif afterStop < 3:
						afterStop -= 1
		else:
			mushMush += 1
			mushNum = -1
		mushNum += 1
	if !spawnPoint && !defMushs:
		get_def(mushs)
		defCounter = 100
		defMushs = true
		isAttack = true
	defCounter -= 1
	if defCounter == 0:
		get_def(mushs)
		defCounter = 100
	if isAttack:
		bombs_attack(mushs)
		isAttack = false
