extends Camera2D

signal error(err_id)

var new_endgame_parameter := {
	"ModeName": Global.get_endgame_parameter().ModeName,
	"EndGameText": "",
	"MatchTimer": "",
	"Mushrooms": 1,
	"MushroomsLost": 0,
	"MineralsMine": 0,
	"MineralsSpend": 0,
	"BgPicture": "",
	"BgAudio": ""
}

export var user_id: int = 0
export var gems: int = 450
export var BASE_POS: Vector2 = Vector2(-1, -24)

export var delta = Vector2(2.5, 2.5)

export var panSpeed = 10.0
export var speed = 10.0
export var zoomspeed = 10.0

export var zoomMin = 0.25
export var zoomMax = 3.0
export var marginX = 200.0
export var marginY = 200.0
export var RANDOM_SHAKE_STRENGTH: float = 15.0
export var SHAKE_DECAY_RATE: float = 5.0

var mousepos = Vector2()
var zoomfactor = 1.0
var not_zooming = true

var selected
var action
var is_blocking = true
var gems_spent = 0

var classes := [
	preload("res://Scenes/Mushrooms/Base.tscn"),
	preload("res://Scenes/Mushrooms/Standart.tscn"),
	preload("res://Scenes/Mushrooms/Bomber.tscn"),
	preload("res://Scenes/Mushrooms/Defender.tscn"),
	preload("res://Scenes/Mushrooms/Attacker.tscn"),
]

const START_X = -75
const END_X = 75
const START_Y = -75
const END_Y = 75

onready var _floor = $"../floor"
onready var _fog = $"../fog"
onready var _tips = $"../tips"
onready var _hud = $"../HUD"
onready var rand = RandomNumberGenerator.new()

var shake_strength: float = 0.0


func _ready():
	rand.randomize()
	set_fog()
	add_gems(0)

	get_parent().connect("ended", self, "show_end_game")
	var base = get_parent().build(BASE_POS, 0, user_id)
	if base.has_method("_on_Miner_timeout"):
		base.connect("res_mined", self, "add_gems")
	remove_fog(0, BASE_POS)
	
	position = _floor.map_to_world(BASE_POS)
	clean_action()


func set_fog():
	for i in range(START_X, END_X):
		for j in range(START_Y, END_Y):
			_fog.set_cellv(Vector2(i, j), 0)


func remove_fog(class_id: int, coords: Vector2):
	var radius = 7
	if class_id == 0:
		radius = 12
	for i in range(-radius, radius + 1): 
		for j in range(-radius, radius + 1):
			_fog.set_cellv(coords + Vector2(i,j), -1);


func add_gems(amount):
	if amount < 0: new_endgame_parameter.MineralsSpend -= amount
	else: new_endgame_parameter.MineralsMine += amount
	gems += amount
	_hud.set_gems(gems)


func _process(delta):
	shake_strength = lerp(shake_strength, 0, SHAKE_DECAY_RATE * delta)
	offset = get_random_offset()
	
	if is_blocking:
		return
	var inpx = (int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")))
	var inpy = (int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up")))
	position.x = lerp(position.x, position.x + inpx * speed * zoom.x, speed * delta)
	position.y = lerp(position.y, position.y + inpy * speed * zoom.y, speed * delta)

	if Input.is_key_pressed(KEY_SPACE):
		if mousepos.x < marginX:
			position.x = lerp(position.x, position.x - abs(mousepos.x - marginX)/marginX * panSpeed * zoom.x, panSpeed * delta)
		elif mousepos.x > OS.window_size.x - marginX:
			position.x = lerp(position.x, position.x + abs(mousepos.x - OS.window_size.x + marginX)/marginX *  panSpeed * zoom.x, panSpeed * delta)
		if mousepos.y < marginY:
			position.y = lerp(position.y, position.y - abs(mousepos.y - marginY)/marginY * panSpeed * zoom.y, panSpeed * delta)
		elif mousepos.y > OS.window_size.y - marginY:
			position.y = lerp(position.y, position.y + abs(mousepos.y - OS.window_size.y + marginY)/marginY * panSpeed * zoom.y, panSpeed * delta)

	#zoom in
	zoom.x = lerp(zoom.x, zoom.x * zoomfactor, zoomspeed * delta)
	zoom.y = lerp(zoom.y, zoom.y * zoomfactor, zoomspeed * delta)
	zoom.x = clamp(zoom.x, zoomMin, zoomMax)
	zoom.y = clamp(zoom.y, zoomMin, zoomMax)

	if not_zooming:
		zoomfactor = 1.0


func get_random_offset() -> Vector2:
	return Vector2(
		rand.randf_range(-shake_strength, shake_strength),
		rand.randf_range(-shake_strength, shake_strength)
	)


func _unhandled_input(event):
	if is_blocking:
		return
	if event is InputEventMouseButton:
		not_zooming = true
		
		if event.is_pressed():
			not_zooming = false
			if event.button_index == BUTTON_WHEEL_UP:
				zoomfactor -= 0.01 * zoomspeed
			if event.button_index == BUTTON_WHEEL_DOWN:
				zoomfactor += 0.01 * zoomspeed
	
	if event is InputEventMouse:
		mousepos = event.position
	
	if event is InputEventMouseButton:
		if !event.is_pressed():
			return

		if InputMap.event_is_action(event, "ui_left_mouse_button"):
			var evpos = get_global_mouse_position() + delta
			var coords = _floor.world_to_map(evpos)

			if action == Global.BUILD and _fog.get_cellv(coords) and get_parent().can_be_built(selected, coords, gems):
				var mushroom = get_parent().build(coords, 1, user_id)
				if mushroom.has_method("_on_Miner_timeout"):
					mushroom.connect("res_mined", self, "add_gems")
				new_endgame_parameter.Mushrooms += 1
				add_gems(-mushroom.cost)
				
				remove_fog(1, coords)
				get_parent().build_roots(selected, coords, 2)
				
				clean_action()
			elif action == Global.ATTACK:
				if get_parent().is_enough_gems(-1, gems, Global.ATTACK):
					if get_parent().can_attack(selected, coords):
						if get_parent().attack(selected, coords):
							add_gems(-Global.I_ATTACK.attack_price)
					else:
						var l = (coords-selected).abs()
						if max(l.x, l.y) > Global.I_ATTACK.attack_radius:
							emit_signal("error", 1)
						else:
							emit_signal("error", 2)
				else:
					emit_signal("error", 0)
				clean_action()
			else:
				var tmp = can_select(coords)
				if tmp != Vector2.INF:
					coords = tmp
					selected = get_parent().get_centered(coords)
					_hud.show_options(get_parent().get_mushroom(selected).abilities)
					return
		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			clean_action()

	if event is InputEventMouseMotion and selected != null:
		var evpos = get_global_mouse_position() + delta
		var coords = $"../floor".world_to_map(evpos)
		if action == Global.BUILD:
			show_build_options(selected, coords)
		elif action == Global.ATTACK:
			show_build_options(selected, coords, true)

	if event.is_pressed() or selected == null: return

	var mushroom = get_parent().get_mushroom(selected)
	if mushroom == null: return
	if InputMap.event_is_action(event, "build") and "min_build_radius" in mushroom:
		process_action(Global.BUILD)
		return
	if InputMap.event_is_action(event, "attack") and mushroom is Attacker:
		process_action(Global.ATTACK)
		return
	if InputMap.event_is_action(event, "explode") and mushroom is Bomber:
		process_action(Global.EXPLODE)
		return
	
	if not mushroom is Standart:
		return
	
	if InputMap.event_is_action(event, "evolve_attack"):
		process_action(Global.E_ATTACK)
		return
	if InputMap.event_is_action(event, "evolve_bomb"):
		process_action(Global.E_BOMB)
		return
	if InputMap.event_is_action(event, "evolve_defender"):
		process_action(Global.E_DEFENDER)
		return


func process_action(action_id):
	action = action_id

	if action == Global.EXPLODE:
		if get_parent().explode(selected):
			shake_strength = RANDOM_SHAKE_STRENGTH
		return

	var mushroom
	if action == Global.E_ATTACK:
		if get_parent().is_enough_gems(4, gems, Global.E_ATTACK):
			mushroom = get_parent().evolve(selected, 4)
			new_endgame_parameter.Mushrooms += 1
		else:
			emit_signal("error", 0)
	elif action == Global.E_BOMB:
		if get_parent().is_enough_gems(2, gems, Global.E_BOMB):
			mushroom = get_parent().evolve(selected, 2)
			new_endgame_parameter.Mushrooms += 1
		else:
			emit_signal("error", 0)
	elif action == Global.E_DEFENDER:
		if get_parent().is_enough_gems(3, gems, Global.E_DEFENDER):
			mushroom = get_parent().evolve(selected, 3)
			new_endgame_parameter.Mushrooms += 1
		else:
			emit_signal("error", 0)
	else:
		return

	if mushroom != null and mushroom.has_method("_on_Miner_timeout"):
		mushroom.connect("res_mined", self, "add_gems")
		add_gems(-mushroom.cost)
	clean_action()


func clean_action():
	selected = null
	action = null
	_hud.show_options([])
	_tips.clear()


func show_build_options(origin: Vector2, coords: Vector2, is_attack = false):
	_tips.clear()
	coords -= Vector2.ONE
	
	if is_attack:
		_tips.set_cellv(coords, 6)
		return

	if _fog.get_cellv(coords) and get_parent().can_be_built(origin, coords + Vector2.ONE, gems): 
		_tips.set_cellv(coords, 0)
	else:
		_tips.set_cellv(coords, 1)


func _on_HUD_game_started():
	is_blocking = false


func show_end_game(win):
	var timer = Timer.new()
	timer.connect("timeout", self, "_on_finisher_timeout", [timer])
	timer.wait_time = 2
	add_child(timer)
	timer.start()
	
	new_endgame_parameter.MatchTimer = _hud.Get_Time()
	if win:
		new_endgame_parameter.EndGameText = "All enemy mycelium \nwas defeated"
		new_endgame_parameter.BgPicture = "WinBg.png"
		new_endgame_parameter.BgAudio = "WinAudio.ogg"
	else:
		new_endgame_parameter.EndGameText = "Your mycelium \nwas defeated"
		new_endgame_parameter.BgPicture = "LoseBg.png"
		new_endgame_parameter.BgAudio = "LoseAudio.ogg"
	Global.set_endgame_parameter(new_endgame_parameter)


func _on_finisher_timeout(timer: Timer):
	timer.stop()
	remove_child(timer)
	get_tree().change_scene("res://Scenes/UI/EndGame.tscn")


func can_select(coords: Vector2) -> Vector2:
	for i in range(3):
		var tmp = coords + Vector2(i,i) 
		if get_parent().objs.has(tmp) and get_parent().objs[tmp].user_id == user_id:
			return tmp
	return Vector2.INF
	
