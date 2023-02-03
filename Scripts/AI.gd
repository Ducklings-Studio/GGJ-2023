extends Node2D

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
var gemsAI = 0
var graph := {}
var reversed_graph := {}

const ENEMY_BASE_COORD_X = -1;
const ENEMY_BASE_COORD_Y = -24;

const AI_BASE_COORD_X = -1;
const AI_BASE_COORD_Y = 24;

func _ready():
	build(Vector2(AI_BASE_COORD_X, AI_BASE_COORD_Y), 0)

func add_gems(amount):
	gemsAI += amount


func built(coords):
	var cell = $"../figures".get_cellv(coords)
	if cell in range(7, 11):
		$"../figures".set_cellv(coords, cell - 6)


func build(coords: Vector2, class_id: int):
	var mushroom = classes[class_id].instance()
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
	mushroom.connect("built", self, "built", [coords])
	
	if class_id != 0:
		add_gems(-mushroom.cost)
	
	objs[coords] = mushroom
	$"../floor".set_cellv(coords, 4)
	
	if class_id in range(1,5):
		$"../figures".set_cellv(coords, class_id + 6)
	else:
		$"../figures".set_cellv(coords, class_id)
	
	if class_id == 0:
		for i in range(-1, 2):
			for j in range(-1, 2):
				objs[coords + Vector2(i,j)] = mushroom

	$"../figures".add_child(mushroom)


func put_mushroom(mushroom: Vector2, coords: Vector2):
	build(coords, 1)
	$"../".build_roots(mushroom, coords, 2)


func is_ground(coords: Vector2):
	return $"../floor".get_cellv(coords) in [0,1,3,4,6,7,8,9,11,13]


func distance(one: Vector2, two: Vector2):
	return sqrt((one.x - two.x) * (one.x - two.x) + (one.y - two.y) * (one.y - two.y))


func get_def(mushs):
	for i in range(0, len(mushs)):
		if distance(mushs[i], enemyBase) < 12 && $"../floor".get_cellv(mushs[i]) == 1:
			evolve(mushs[i], 4) # todo: change to def

var bombs = []

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
	while neatestDist > 12:
		nearestMush = go_to_enemy(nearestMush, enemyBase)
	bombs.append(plant_bomb(nearestMush, enemyBase))


func go_to_enemy(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if distance(Vector2(i, j), base) < 2:
				continue;
			if can_be_built(mush, Vector2(i, j)): #fix can_be_built, doesn't work, or fix my hands
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


func can_be_built(origin: Vector2, coords: Vector2):
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
	return true


func ruin(coords: Vector2):
	var mushroom = objs[coords]
	if mushroom == null: return

	for i in range(-1, 2):
		for j in range(-1, 2):
			objs.erase(coords + Vector2(i,j))

	$"../figures".set_cellv(coords, -1)
	$"../figures".remove_child(mushroom)


func evolve(coords: Vector2, class_id: int):
	ruin(coords)
	build(coords, class_id)

	if class_id != 3:
		return
	var source = reversed_graph[coords]
	if objs.has(source) and objs[source] is Defender:
		$"../".build_roots(source, coords, 10)
	if !graph.has(coords):
		return
	for i in graph[coords]:
		if objs.has(i) and objs[i] is Defender:
			$"../".build_roots(coords, i, 10)


func explose(coords: Vector2):
	var effect = effects[0].instance()
	effect.position = $"../figures".map_to_world(coords)
	$"../figures".add_child(effect)
	
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
			$"../figures".set_cellv(tmp_coords, -1)
			$"../floor".set_cellv(tmp_coords, 0)


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
		return bestPosition
	return null


func active_bombs():
	for i in range(0, len(bombs)):
		var cell = $"../figures".get_cellv(bombs[i])
		if cell == 2:
			explose(bombs[i])
			spawnPoint = true


func select_enemy(mushs, positions):
	if len(playerPositions) && len(mushs):
		var nearest = distance(positions[0], mushs[0])
		var nearestBase = positions[0]
		for i in range(0, len(positions)):
			for j in range(0, len(mushs)):
				if distance(mushs[j], positions[i]) < nearest:
					nearest = distance(mushs[j], positions[i])
					nearestBase = positions[i]
		return nearestBase
	return null

var base = Vector2(AI_BASE_COORD_X, AI_BASE_COORD_Y)
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
var mushsCoords := [Vector2(1, 4), Vector2(4, 0), Vector2(-4, 0), Vector2(3, -2),
	Vector2(0, -3),  Vector2(-3, -3), Vector2(-3, 0), Vector2(-8, -3)]
var enemyMush = []
var enemyBase = Vector2(ENEMY_BASE_COORD_X, ENEMY_BASE_COORD_Y)
var spawnPoint = true
var afterStop = 3
var defMushs = false
var defCounter = 100
var isAttack = false
var playerPositions = []


func _on_Timer_timeout():
	active_bombs()
	playerPositions = $"../".objs.keys().slice(0, 0) + $"../".objs.keys().slice(9, len($"../".objs.keys()))
	var nowPoint = len(mushs)
	while nowPoint == len(mushs) && spawnPoint:
		if mushNum < len(baseCoords) && !mushMush && is_ground(base+baseCoords[mushNum]):
			if can_be_built(base, base+baseCoords[mushNum]):
				put_mushroom(base, base+baseCoords[mushNum])
				mushs.append(base+baseCoords[mushNum])
		elif mushMush && mushNum < len(mushsCoords) && is_ground(mushs[mushMush - 1]+mushsCoords[mushNum]):
			if can_be_built(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum]):
				put_mushroom(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum])
				mushs.append(mushs[mushMush - 1]+mushsCoords[mushNum])
				var checkBase = select_enemy(mushs, playerPositions)
				if checkBase:
					enemyBase = checkBase
				if distance(mushs[mushMush - 1]+mushsCoords[mushNum], enemyBase) < 10:
					afterStop -= 1
				if afterStop == 0:
					spawnPoint = false
				elif afterStop < 3:
					afterStop -= 1
		elif !mushMush:
			mushNum += 1
			if mushNum >= len(baseCoords):
				mushMush += 1
			continue;
		elif mushNum >= len(mushsCoords):
			mushMush += 1
			mushNum = -1
		elif is_ground(mushs[mushMush - 1]+mushsCoords[mushNum]):
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
