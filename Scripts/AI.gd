extends Node2D

export var user_id: int = 1
export var gems: int = 700
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
var evolves = {}

func bombs_attack(mushs, positions):
	var nearestEnemy = select_enemy(mushs, playerPositions)
	if nearestEnemy.dist < 10:
		targets.append({"killer": nearestEnemy.enemy, "victim": nearestEnemy.base})
	else:
		spawnPoint = true
		defMushs = true
		return
	if !nearestEnemy:
		return
	
	while nearestEnemy.dist > 12:
		nearestEnemy.base = go_to_enemy(nearestEnemy.enemy, nearestEnemy.base)
	var newBomb = plant_bomb(nearestEnemy.enemy, nearestEnemy.base)
	if newBomb && !evolves.has(nearestEnemy.enemy):
		evolves[newBomb] = {
			"type": "bomb"
		}
		targets.append({"killer": newBomb, "victim": nearestEnemy.base})
	if !newBomb && !evolves.has(nearestEnemy.enemy) && !waitForBomb && nearestEnemy.dist < 3:
		evolves[nearestEnemy.enemy] = {
			"type": "bomb"
		}


func attacker_go(mushs, positions):
	var nearestEnemy = select_enemy(mushs, playerPositions)
	if nearestEnemy.dist >= 10:
		return
	targets.append({"killer": nearestEnemy.enemy, "victim": nearestEnemy.base})
	evolves[nearestEnemy.enemy] = {
		"type": "hit"
	}


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
		putPoint = false
		return bestPosition
	return mush


func plant_bomb(mush: Vector2, base: Vector2):
	var bestPosition = null
	var bestDistance = null
	for i in range(min(mush.x, base.x), max(mush.x, base.x)+1):
		for j in range(min(mush.y, base.y), max(mush.y, base.y)+1):
			if Vector2(i, j).distance_to(mush) < 2:
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
		putPoint = false
		waitForBomb = true
		return bestPosition
	return null


func active_bombs():
	for i in bombs:
		var mushroom = get_parent().get_mushroom(i)
		if mushroom is Bomber:
			get_parent().explode(i)
			spawnPoint = true
			waitForBomb = false


func do_attack():
	for i in attackers:
		var mushroom = get_parent().get_mushroom(i)
		if mushroom is Attacker:
			for target in targets:
				if target.killer == i:
					if get_parent().is_enough_gems(-1, gems, Global.ATTACK) and get_parent().can_attack(i, target.victim):
						get_parent().attack(i, target.victim)
						add_gems(-Global.I_ATTACK.attack_price)


func wait_evolve():
	for coords in evolves.keys():
		if evolves[coords].type == "bomb":
			var bomb = coords
			var mushroom = get_parent().evolve(bomb, 2)
			if mushroom:
				bombs.append(bomb)
				evolves.erase(bomb)
		elif evolves[coords].type == "hit":
			var attacker = coords
			var mushroom = get_parent().evolve(attacker, 4)
			if mushroom:
				attackers.append(attacker)
				evolves.erase(attacker)
				

func update_targets():
	for target in targets:
		if !playerPositions.has(target.victim) || !playerPositions.has(target.killer) && !evolves.has(target.killer):
			targets.erase(target)


func select_enemy(mushs, positions):
	if len(positions) && len(mushs):
		var nearest = AI_BASE_COORDS.distance_to(enemyBase)
		var nearestEnemy = enemyBase
		var nearestBase = AI_BASE_COORDS
		for pos in positions:
			for m in mushs:
				var flag = true
				for target in targets:
					if target.victim == pos || target.killer == m:
						flag = false
				if flag:
					if get_parent().objs[pos].user_id != user_id and m.distance_to(pos) < nearest:
						nearest = m.distance_to(pos)
						nearestEnemy = pos
						nearestBase = m
		return {"base": nearestEnemy, "dist": nearest, "enemy": nearestBase}
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
var isBombAttack = false
var isAttack = false
var attackers = []
var targets = []
var playerPositions = []
var putPoint = true
var waitForBomb = false


func _on_Timer_timeout():
	active_bombs()
	wait_evolve()
	update_targets()
	do_attack()
	playerPositions = $"../".objs.keys()
	
	mushs.clear()
	for pos in playerPositions:
		if $"../".objs[pos].user_id == user_id:
			mushs.append(pos)
	putPoint = true
	while putPoint && spawnPoint && !waitForBomb:
		if !get_parent().is_enough_gems(1, gems, Global.BUILD):
			break
		if mushNum < len(baseCoords) && !mushMush:
			if get_parent().can_be_built(AI_BASE_COORDS, AI_BASE_COORDS+baseCoords[mushNum], gems, user_id):
				put_mushroom(AI_BASE_COORDS, AI_BASE_COORDS+baseCoords[mushNum])
				putPoint = false
			else:
				mushNum += 1
				break
		elif mushMush && mushNum < len(mushsCoords) && mushMush <= len(mushs):
			if get_parent().can_be_built(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum], gems, user_id) && !evolves.has(mushs[mushMush - 1]) && !bombs.has(mushs[mushMush - 1]):
				put_mushroom(mushs[mushMush - 1], mushs[mushMush - 1]+mushsCoords[mushNum])
				putPoint = false
				var nearestEnemy
				var isEnemy = select_enemy(mushs, playerPositions)
				if isEnemy:
					nearestEnemy = isEnemy
				if nearestEnemy.dist < 10:
					spawnPoint = false
					defMushs = false
		elif !mushMush:
			mushNum += 1
			if mushNum >= len(baseCoords):
				mushMush += 1
			break
		elif mushMush:
			mushMush += 1
			mushNum = 0
			break
		mushNum += 1
	if spawnPoint:
		var foundEnemy = select_enemy(mushs, playerPositions)
		if foundEnemy:
			if foundEnemy.dist < 10:
				spawnPoint = false

	if !spawnPoint && !defMushs && get_parent().is_enough_gems(4, gems, Global.BUILD):
		if !waitForBomb:
			isBombAttack = true
		else:
			var nearEnemy = select_enemy(mushs, playerPositions)
			if nearEnemy.dist < 10 && get_parent().can_attack(nearEnemy.base, nearEnemy.enemy):
				isAttack = true
	#defCounter -= 1
	#if defCounter == 0 and get_parent().is_enough_gems(4, gems, Global.BUILD):
	#	defMushs = get_def(mushs)
	#	defCounter = 100
	if isBombAttack && get_parent().is_enough_gems(2, gems, Global.BUILD) && !waitForBomb:
		bombs_attack(mushs, playerPositions)
		isBombAttack = false
	if isAttack:
		attacker_go(mushs, playerPositions)
		isAttack = false
