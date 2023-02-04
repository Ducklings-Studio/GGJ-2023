extends Node2D

export var user_id: int = 1
export var gems: int = 1000
export var AI_BASE_COORDS: Vector2 = Vector2(-1, 24)


func _ready():
	var mushroom = get_parent().build(AI_BASE_COORDS, 0, user_id)
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")


func add_gems(amount):
	gems += amount


func put_mushroom(source: Vector2, coords: Vector2):
	var mushroom = get_parent().build(coords, 1, user_id)
	if mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
	add_gems(-mushroom.cost)

	get_parent().build_roots(source, coords, 2)


func get_def(mushs):
	for m in mushs:
		if m.distance_to(enemyBase) < 12 && get_parent().get_mushroom(m) is Standart:
			get_parent().evolve(m, 4) # todo: change to def
			return true
	return false

var bombs = []

func bombs_attack(mushs):
	var nearestMush
	var neatestDist
	if len(mushs):
		nearestMush = mushs[0]
		neatestDist = mushs[0].distance_to(enemyBase)
	else:
		nearestMush = AI_BASE_COORDS
		neatestDist = AI_BASE_COORDS.distance_to(enemyBase)
	for i in range(1, len(mushs)):
		if mushs[i].distance_to(enemyBase) < neatestDist:
			nearestMush = mushs[i]
			neatestDist = mushs[i].distance_to(enemyBase)
	while neatestDist > 12:
		nearestMush = go_to_enemy(nearestMush, enemyBase)
	var newBomb = plant_bomb(nearestMush, enemyBase)
	if newBomb && !bombs.has(nearestMush):
		bombs.append(newBomb)
	if !newBomb && !bombs.has(nearestMush):
		get_parent().evolve(nearestMush, 2)
		bombs.append(nearestMush)


func go_to_enemy(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if Vector2(i, j).distance_to(base) < 2:
				continue;
			if get_parent().can_be_built(mush, Vector2(i, j), gems, user_id):
				if bestPosition == null:
					bestPosition = Vector2(i, j)
					bestDistance = Vector2(i, j).distance_to(base)
				else:
					if Vector2(i, j).distance_to(base) < bestDistance:
						bestPosition = Vector2(i, j)
						bestDistance = Vector2(i, j).distance_to(base)
	if bestPosition != null:
		put_mushroom(mush, bestPosition)
		#mushs.append(bestPosition)
		return bestPosition
	return mush


func plant_bomb(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if Vector2(i, j).distance_to(base) < 2:
				continue;
			if get_parent().can_be_built(mush, Vector2(i, j), gems, user_id):
				if bestPosition == null:
					bestPosition = Vector2(i, j)
					bestDistance = Vector2(i, j).distance_to(base)
				else:
					if Vector2(i, j).distance_to(base) < bestDistance:
						bestPosition = Vector2(i, j)
						bestDistance = Vector2(i, j).distance_to(base)
	if bestPosition != null:
		put_mushroom(mush, bestPosition)
		#mushs.append(bestPosition)
		get_parent().evolve(bestPosition, 2)
		return bestPosition
	return null


func active_bombs():
	for i in bombs:
		var mushroom = get_parent().get_mushroom(i)
		if mushroom is Bomber:
			get_parent().explode(i)
			spawnPoint = true
			afterStop = 3


func select_enemy(mushs, positions):
	if len(positions) && len(mushs):
		var nearest = positions[0].distance_to(mushs[0])
		var nearestBase = positions[0]
		for pos in positions:
			for m in mushs:
				if get_parent().objs[pos].user_id != user_id and m.distance_to(pos) < nearest:
					nearest = m.distance_to(pos)
					nearestBase = pos
		return nearestBase
	return null


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
onready var enemyBase = $"../Camera2D".BASE_POS
var spawnPoint = true
var afterStop = 3
var defMushs = false
var defCounter = 100
var isAttack = false
var playerPositions = []


func _on_Timer_timeout():
	active_bombs()
	playerPositions = $"../".objs.keys()
	mushs.clear()
	for pos in playerPositions:
		if $"../".objs[pos].user_id == user_id:
			mushs.append(pos)
	var nowPoint = len(mushs)
	while nowPoint == len(mushs) && spawnPoint:
		if !get_parent().is_enough_gems(1, gems, Global.BUILD):
			break
		if mushNum < len(baseCoords) && !mushMush && get_parent().is_ground(AI_BASE_COORDS+baseCoords[mushNum]):
			if get_parent().can_be_built(AI_BASE_COORDS, AI_BASE_COORDS+baseCoords[mushNum], gems, user_id):
				put_mushroom(AI_BASE_COORDS, AI_BASE_COORDS+baseCoords[mushNum])
				#mushs.append(AI_BASE_COORDS+baseCoords[mushNum])
		elif mushNum >= len(mushsCoords) && mushNum < len(baseCoords):
			mushNum += 1
			break
		elif mushMush && mushNum < len(mushsCoords) && get_parent().is_ground(mushs[mushMush - 1]+mushsCoords[mushNum]):
			if get_parent().can_be_built(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum], gems, user_id):
				put_mushroom(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum])
				#mushs.append(mushs[mushMush - 1]+mushsCoords[mushNum])
				var checkBase = select_enemy(mushs, playerPositions)
				if checkBase:
					enemyBase = checkBase
				if (mushs[mushMush - 1]+mushsCoords[mushNum]).distance_to(enemyBase) < 10:
					afterStop -= 1
				if afterStop == 0:
					spawnPoint = false
					defMushs = false
				elif afterStop < 3:
					afterStop -= 1
		elif !mushMush:
			mushNum += 1
			if mushNum >= len(baseCoords):
				mushMush += 1
			continue
		elif mushNum >= len(mushsCoords) or get_parent().is_ground(mushs[mushMush - 1]+mushsCoords[mushNum]):
			mushMush += 1
			mushNum = -1
		mushNum += 1
	if !spawnPoint && !defMushs && get_parent().is_enough_gems(4, gems, Global.BUILD):
		defMushs = get_def(mushs)
		if !defMushs:
			defCounter = 100
			isAttack = true
	defCounter -= 1
	if defCounter == 0 and get_parent().is_enough_gems(4, gems, Global.BUILD):
		defMushs = get_def(mushs)
		defCounter = 100
	if isAttack && get_parent().is_enough_gems(2, gems, Global.BUILD):
		bombs_attack(mushs)
		isAttack = false
