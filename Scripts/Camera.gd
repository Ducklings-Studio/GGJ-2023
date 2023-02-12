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
	get_parent().connect("mushroom_destroyed", self, "_on_mushroom_destroyed")
	var base = get_parent().build(BASE_POS, 0, user_id)
	if base.has_method("_on_Miner_timeout"):
		base.connect("res_mined", self, "add_gems")
	remove_fog(0, BASE_POS)
	
	position = _floor.map_to_world(BASE_POS)
	_hud.show_options([])
	clean_action()
	
	new_endgame_parameter.MineralsMine = gems


func _on_mushroom_destroyed(coords):
	if coords == selected:
		select(null)


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
	var inpx = (int(Input.is_action_pressed("MOVE_RIGHT")) - int(Input.is_action_pressed("MOVE_LEFT")))
	var inpy = (int(Input.is_action_pressed("MOVE_DOWN")) - int(Input.is_action_pressed("MOVE_UP")))
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
					var err = get_parent().can_attack_user(selected, coords)
					if err == 0 and get_parent().attack(selected, coords):
						add_gems(-Global.I_ATTACK.attack_price)
					else:
						emit_signal("error", err)
				else:
					emit_signal("error", 1)
				clean_action()
			else:
				var tmp = can_select(coords)
				if tmp != Vector2.INF:
					coords = tmp
					select(get_parent().get_centered(coords))
					var m = get_parent().get_mushroom(selected)
					return
		elif InputMap.event_is_action(event, "ui_right_mouse_button"):
			select(null)
			clean_action()

	if event is InputEventMouseMotion and selected != null:
		var evpos = get_global_mouse_position() + delta
		var coords = $"../floor".world_to_map(evpos)
		if action == Global.BUILD:
			show_build_options(selected, coords)
		elif action == Global.ATTACK:
			show_build_options(selected, coords, true)


func select(coords):
	if coords != null:
		if selected != null:
			_tips.set_cellv(selected, -1)
			var m = get_parent().get_mushroom(selected)
			if m != null && m.has_signal("build"):
				m.disconnect("built", self, "show_selected")
		selected = coords
		var m = get_parent().get_mushroom(selected)
		_hud.show_options(m.abilities)
		if not m.is_connected("built", self, "show_selected"):
			m.connect("built", self, "show_selected")
		show_selected()
	else:
		if selected != null:
			_tips.set_cellv(selected, -1)
			var m = get_parent().get_mushroom(selected)
			if m != null && m.has_signal("build"):
				m.disconnect("built", self, "show_selected")
		selected = null
		_hud.show_options([])


func process_action(action_id):
	var mushroom = get_parent().get_mushroom(selected)
	if mushroom == null: return
	if not get_parent().objs.has(selected) or get_parent().objs[selected].user_id != user_id:
		return
	
	action = action_id
	
	if action == Global.ATTACK and not mushroom is Attacker:
		action = null
		return
	
	if action == Global.BUILD and not "min_build_radius" in mushroom:
		action = null
		return
	
	if action == Global.EXPLODE and mushroom is Bomber:
		if get_parent().explode(selected):
			shake_strength = RANDOM_SHAKE_STRENGTH
			select(null)
		return

	if action == Global.E_ATTACK and mushroom is Standart:
		if get_parent().is_enough_gems(4, gems, Global.E_ATTACK):
			mushroom = get_parent().evolve(selected, 4)
			new_endgame_parameter.Mushrooms += 1
			add_gems(-mushroom.cost)
		else:
			emit_signal("error", 1)
	elif action == Global.E_BOMB and mushroom is Standart:
		if get_parent().is_enough_gems(2, gems, Global.E_BOMB):
			mushroom = get_parent().evolve(selected, 2)
			new_endgame_parameter.Mushrooms += 1
			add_gems(-mushroom.cost)
		else:
			emit_signal("error", 1)
	elif action == Global.E_DEFENDER and mushroom is Standart:
		if get_parent().is_enough_gems(3, gems, Global.E_DEFENDER):
			mushroom = get_parent().evolve(selected, 3)
			new_endgame_parameter.Mushrooms += 1
			add_gems(-mushroom.cost)
		else:
			emit_signal("error", 1)
	else:
		return

	if selected != null:
		_tips.set_cellv(selected, -1)
	clean_action()


var _prev_coords
func clean_action():
	action = null
	if _prev_coords != null:
		_tips.set_cellv(_prev_coords, -1)


func show_build_options(origin: Vector2, coords: Vector2, is_attack = false):
	if _prev_coords != null:
		_tips.set_cellv(_prev_coords, -1)
	coords -= Vector2.ONE
	_prev_coords = coords
	
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
		new_endgame_parameter.EndGameText = "K_WIN"
		new_endgame_parameter.BgPicture = "WinBg.png"
		new_endgame_parameter.BgAudio = "WinAudio.ogg"
	else:
		new_endgame_parameter.EndGameText = "K_LOST"
		new_endgame_parameter.BgPicture = "LoseBg.png"
		new_endgame_parameter.BgAudio = "LoseAudio.ogg"
	Global.set_endgame_parameter(new_endgame_parameter)


func _on_finisher_timeout(timer: Timer):
	timer.stop()
	remove_child(timer)
	get_tree().change_scene("res://Scenes/UI/EndGame.tscn")


func can_select(coords: Vector2) -> Vector2:
	for i in range(3):
		var arr = [Vector2(i, i)]
		if i != 2:
			arr = [Vector2(i+1, i), Vector2(i, i), Vector2(i, i+1)]
		for r in arr:
			var tmp = coords + r
			if get_parent().objs.has(tmp) and get_parent().objs[tmp].user_id == user_id:
				return tmp
	return Vector2.INF


func show_selected():
	if selected == null: return
	var m = get_parent().get_mushroom(selected)
	if get_parent().is_not_ready(selected): return
	var idx
	if m is Base:
		idx = 11
	elif m is Standart:
		idx = 7
	elif m is Bomber:
		idx = 8
	elif m is Defender:
		idx = 9
	elif m is Attacker:
		idx = 10
	else:
		return
	_tips.set_cellv(selected, idx)
